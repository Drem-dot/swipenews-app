// reply_indicator.dart - Separate widget to avoid full rebuild

import 'package:flutter/material.dart';
import '../models/comment.dart';

class ReplyIndicator extends StatelessWidget {
  final Comment? replyingToComment;
  final VoidCallback onCancel;

  const ReplyIndicator({
    super.key,
    required this.replyingToComment,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: replyingToComment != null ? 48 : 0,
      child: replyingToComment != null
          ? Container(
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
                      'Đang phản hồi ${replyingToComment!.userName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onCancel,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}