// comment_sheet.dart - Optimized V2 with ValueNotifier

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:swipenews/models/comment.dart';

import '../widgets/comment_list_item.dart';
import '../widgets/comment_input_field.dart';
import '../widgets/reply_indicator.dart';
import '../providers/comment_provider.dart';

class CommentSheet extends StatefulWidget {
  final String articleId;
  final User currentUser;

  const CommentSheet({
    super.key,
    required this.articleId,
    required this.currentUser,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  // Use ValueNotifier to avoid full rebuild
  final ValueNotifier<Comment?> _replyingToComment = ValueNotifier(null);
  
  // Track optimistic comments locally
  final ValueNotifier<List<Comment>> _optimisticComments = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load comments and likes in background
    final provider = context.read<CommentProvider>();
    provider.getCommentsStream(widget.articleId).first.then((comments) {
      if (comments.isNotEmpty) {
        final commentIds = comments.map((c) => c.id).toList();
        provider.loadUserLikesForComments(widget.articleId, commentIds);
      }
    });
  }

  void _handleReplyTapped(Comment comment) {
    _replyingToComment.value = comment;
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    _replyingToComment.value = null;
    _commentController.clear();
  }

  Future<void> _submitComment(String text) async {
    if (text.isEmpty) return;

    final provider = context.read<CommentProvider>();
    final replyTo = _replyingToComment.value;
    
    // Create optimistic comment
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticComment = Comment(
      id: tempId,
      articleId: widget.articleId,
      parentId: replyTo?.parentId ?? replyTo?.id,
      userId: widget.currentUser.uid,
      userName: widget.currentUser.displayName ?? 'Anonymous',
      userAvatarUrl: widget.currentUser.photoURL,
      text: text,
      replyingToUserName: replyTo?.userName,
      timestamp: Timestamp.now(),
      likeCount: 0,
      replyCount: 0,
      isEdited: false,
    );

    // Add optimistically
    _optimisticComments.value = [..._optimisticComments.value, optimisticComment];
    
    // Clear input immediately for better UX
    _commentController.clear();
    _replyingToComment.value = null;
    _commentFocusNode.unfocus();

    try {
      await provider.addComment(
        articleId: widget.articleId,
        text: text,
        parentId: optimisticComment.parentId,
        replyingToUserName: optimisticComment.replyingToUserName,
      );

      // Remove optimistic comment after success
      _optimisticComments.value = _optimisticComments.value
          .where((c) => c.id != tempId)
          .toList();
    } catch (e) {
      // Remove on error and show message
      _optimisticComments.value = _optimisticComments.value
          .where((c) => c.id != tempId)
          .toList();
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi bình luận'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    _replyingToComment.dispose();
    _optimisticComments.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header - Static, won't rebuild
          _buildHeader(),
          
          const Divider(height: 1),

          // Comments list - Only this part uses StreamBuilder
          Expanded(
            child: _CommentsList(
              articleId: widget.articleId,
              scrollController: _scrollController,
              optimisticComments: _optimisticComments,
              onReplyTapped: _handleReplyTapped,
            ),
          ),

          // Reply indicator - Isolated with ValueListenableBuilder
          ValueListenableBuilder<Comment?>(
            valueListenable: _replyingToComment,
            builder: (context, replyingTo, _) {
              return ReplyIndicator(
                replyingToComment: replyingTo,
                onCancel: _cancelReply,
              );
            },
          ),

          // Input field - Also isolated
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ValueListenableBuilder<Comment?>(
              valueListenable: _replyingToComment,
              builder: (context, replyingTo, _) {
                return CommentInputField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  hintText: replyingTo != null 
                      ? 'Phản hồi ${replyingTo.userName}...'
                      : 'Viết bình luận...',
                  onPost: _submitComment,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Bình luận",
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Separate widget for comments list to isolate rebuilds
class _CommentsList extends StatelessWidget {
  final String articleId;
  final ScrollController scrollController;
  final ValueNotifier<List<Comment>> optimisticComments;
  final Function(Comment) onReplyTapped;

  const _CommentsList({
    required this.articleId,
    required this.scrollController,
    required this.optimisticComments,
    required this.onReplyTapped,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Comment>>(
      stream: context.read<CommentProvider>().getCommentsStream(articleId),
      builder: (context, snapshot) {
        // Show loading only on first load
        if (snapshot.connectionState == ConnectionState.waiting && 
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ValueListenableBuilder<List<Comment>>(
          valueListenable: optimisticComments,
          builder: (context, optimistic, _) {
            final realComments = snapshot.data ?? [];
            
            // Merge real with optimistic comments
            final rootOptimistic = optimistic.where((c) => c.parentId == null).toList();
            final allComments = [...realComments, ...rootOptimistic];

            if (allComments.isEmpty) {
              return const Center(
                child: Text(
                  "Chưa có bình luận nào.\nHãy là người đầu tiên!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            // Use ListView.builder with itemExtent for better performance
            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: allComments.length,
              itemBuilder: (context, index) {
                final comment = allComments[index];
                return CommentListItem(
                  key: ValueKey(comment.id),
                  articleId: articleId,
                  comment: comment,
                  onReplyTapped: onReplyTapped,
                );
              },
            );
          },
        );
      },
    );
  }
}