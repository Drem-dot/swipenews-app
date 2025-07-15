// lib/widgets/action_toolbar.dart

import 'package:flutter/material.dart';

class ActionToolbar extends StatelessWidget {
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLikePressed;
  final VoidCallback onSavePressed;
  final VoidCallback onSharePressed;
  final VoidCallback onDetailPressed;
  final VoidCallback onCommentPressed;

  const ActionToolbar({
    super.key,
    required this.isLiked,
    required this.isSaved,
    required this.onLikePressed,
    required this.onSavePressed,
    required this.onSharePressed,
    required this.onDetailPressed,
    required this.onCommentPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.article_outlined, color: Colors.white, size: 28),
            onPressed: onDetailPressed,
            tooltip: 'Đọc chi tiết',
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.redAccent : Colors.white,
                  size: 28,
                ),
                onPressed: onLikePressed,
                tooltip: isLiked ? 'Bỏ thích' : 'Thích',
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: onSavePressed,
                tooltip: isSaved ? 'Bỏ lưu' : 'Lưu',
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.comment_outlined, color: Colors.white, size: 28),
                onPressed: onCommentPressed,
                tooltip: 'Bình luận',
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white, size: 28),
                onPressed: onSharePressed,
                tooltip: 'Chia sẻ',
              ),
            ],
          ),
        ],
      ),
    );
  }
}