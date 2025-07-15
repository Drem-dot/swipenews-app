// comment_list_item.dart - Optimized version with local state management

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/comment.dart';
import '../providers/comment_provider.dart';
import 'package:provider/provider.dart';

class CommentListItem extends StatefulWidget {
  final String articleId;
  final Comment comment;
  final Function(Comment comment) onReplyTapped;
  final int depth;

  const CommentListItem({
    super.key,
    required this.articleId,
    required this.comment,
    required this.onReplyTapped,
    this.depth = 0,
  });

  @override
  State<CommentListItem> createState() => _CommentListItemState();
}

class _CommentListItemState extends State<CommentListItem> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Keep alive to prevent rebuild
  @override
  bool get wantKeepAlive => true;
  
  late final Stream<List<Comment>> repliesStream;
  bool showReplies = false;
  
  // Local state for like - không depend vào provider
  late bool isLiked;
  late int likeCount;
  bool isProcessingLike = false;
  
  // Animation cho like button
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize local state
    final provider = Provider.of<CommentProvider>(context, listen: false);
    isLiked = provider.isCommentLiked(widget.comment.id);
    likeCount = widget.comment.likeCount;
    
    repliesStream = provider.getRepliesStream(widget.articleId, widget.comment.id);
    
    // Setup animation
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp timestamp) {
    return timeago.format(timestamp.toDate(), locale: 'vi');
  }

  double get leftPadding => widget.depth * 20.0;

  // Optimized like handler - chỉ update local state
  void _handleLike() async {
    if (isProcessingLike || !mounted) return;
    
    setState(() {
      isProcessingLike = true;
      // Optimistic update
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    // Animate
    _likeAnimationController.forward().then((_) {
      if (mounted) {
        _likeAnimationController.reverse();
      }
    });

    try {
      // Call API without listening to provider
      final provider = Provider.of<CommentProvider>(context, listen: false);
      await provider.toggleLike(
        articleId: widget.articleId,
        commentId: widget.comment.id,
        parentCommentId: widget.comment.parentId,
      );
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          isLiked = !isLiked;
          likeCount += isLiked ? 1 : -1;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể thích bình luận'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessingLike = false;
        });
      }
    }
  }

  void _toggleShowReplies() {
    setState(() {
      showReplies = !showReplies;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final displayName = widget.comment.userName.isNotEmpty 
        ? widget.comment.userName 
        : 'Người dùng';

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: widget.comment.userAvatarUrl != null
                    ? NetworkImage(widget.comment.userAvatarUrl!)
                    : null,
                radius: widget.depth == 0 ? 18 : 16,
                child: widget.comment.userAvatarUrl == null
                    ? Icon(Icons.person, size: widget.depth == 0 ? 18 : 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                          if (widget.comment.replyingToUserName != null)
                            Text(
                              '@${widget.comment.replyingToUserName}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            widget.comment.text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Action buttons
                    Row(
                      children: [
                        // Like button với local state
                        GestureDetector(
                          onTap: _handleLike,
                          child: AnimatedBuilder(
                            animation: _likeAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _likeAnimation.value,
                                child: Row(
                                  children: [
                                    Text(
                                      'Thích',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isLiked ? Colors.blue : Colors.grey[600],
                                      ),
                                    ),
                                    if (isProcessingLike)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: SizedBox(
                                          width: 10,
                                          height: 10,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Reply button
                        GestureDetector(
                          onTap: () => widget.onReplyTapped(widget.comment),
                          child: Text(
                            'Phản hồi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Timestamp
                        Text(
                          _formatTimestamp(widget.comment.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        // Like count với local state
                        if (likeCount > 0) ...[
                          const SizedBox(width: 16),
                          Text(
                            '$likeCount thích',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Replies section với animation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: StreamBuilder<List<Comment>>(
              stream: repliesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final replies = snapshot.data!;
                if (replies.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Toggle replies button
                    if (!showReplies)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 26),
                        child: GestureDetector(
                          onTap: _toggleShowReplies,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 1,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${replies.length} phản hồi',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Show replies với animation
                    if (showReplies) ...[
                      ...replies.map((reply) => CommentListItem(
                        key: ValueKey(reply.id), // Important for performance
                        articleId: widget.articleId,
                        comment: reply,
                        onReplyTapped: widget.onReplyTapped,
                        depth: widget.depth + 1,
                      )),
                      
                      // Hide replies button
                      if (replies.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 26),
                          child: GestureDetector(
                            onTap: _toggleShowReplies,
                            child: Text(
                              'Ẩn phản hồi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}