// comment_section.dart - Main comment section with unified reply input

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment.dart';
import '../providers/comment_provider.dart';
import 'comment_list_item.dart';
import 'comment_input_field.dart';

class CommentSection extends StatefulWidget {
  final String articleId;

  const CommentSection({
    super.key,
    required this.articleId,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Reply state
  Comment? _replyingToComment;
  
  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleReplyTapped(Comment comment) {
    setState(() {
      _replyingToComment = comment;
    });
    
    // Focus on input field
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
    _commentController.clear();
  }

  Future<void> _postComment(String text) async {
    final provider = Provider.of<CommentProvider>(context, listen: false);
    
    try {
      await provider.addComment(
        articleId: widget.articleId,
        text: text,
        parentId: _replyingToComment?.parentId ?? _replyingToComment?.id, // Always reply to root comment
        replyingToUserName: _replyingToComment?.userName,
      );
      
      // Clear reply state after successful post
      _cancelReply();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi bình luận: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CommentProvider>(context);

    return Column(
      children: [
        // Comments list
        Expanded(
          child: StreamBuilder<List<Comment>>(
            stream: provider.getCommentsStream(widget.articleId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Lỗi: ${snapshot.error}'),
                );
              }

              final comments = snapshot.data ?? [];

              if (comments.isEmpty) {
                return const Center(
                  child: Text(
                    'Chưa có bình luận nào.\nHãy là người đầu tiên!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  return CommentListItem(
                    articleId: widget.articleId,
                    comment: comments[index],
                    onReplyTapped: _handleReplyTapped,
                  );
                },
              );
            },
          ),
        ),
        
        // Reply indicator
        if (_replyingToComment != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.reply, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đang phản hồi ${_replyingToComment!.userName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _cancelReply,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        
        // Single input field at bottom
        CommentInputField(
          controller: _commentController,
          focusNode: _focusNode,
          hintText: _replyingToComment != null 
              ? 'Phản hồi ${_replyingToComment!.userName}...'
              : 'Viết bình luận...',
          onPost: _postComment,
        ),
      ],
    );
  }
}