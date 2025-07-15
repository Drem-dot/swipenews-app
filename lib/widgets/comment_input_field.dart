// comment_input_field.dart

import 'package:flutter/material.dart';

class CommentInputField extends StatefulWidget {
  final Future<void> Function(String text) onPost;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;

  const CommentInputField({
    super.key,
    required this.onPost,
    required this.controller,
    required this.focusNode,
    this.hintText = "Viết bình luận...",
  });

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  bool _isPosting = false;

  Future<void> _submit() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty || _isPosting) return;

    try {
      setState(() {
        _isPosting = true;
      });

      await widget.onPost(text);
      widget.controller.clear();
      widget.focusNode.unfocus();
    } catch (e) {
      // Có thể hiển thị thông báo lỗi ở đây nếu cần
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
              onSubmitted: (_) => _submit(),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          _isPosting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _submit,
                ),
        ],
      ),
    );
  }
}