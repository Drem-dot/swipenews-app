// lib/widgets/frosted_panel.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// Một widget panel có hiệu ứng kính mờ, với vùng nội dung có thể cuộn
/// và vùng hành động được ghim ở dưới cùng.
class FrostedPanel extends StatelessWidget {
  /// Widget chứa nội dung chính, sẽ được đặt trong một vùng có thể cuộn.
  final Widget scrollableContent;

  /// Widget chứa các nút hành động, sẽ được ghim ở dưới cùng của panel.
  final Widget fixedActions;

  const FrostedPanel({
    super.key,
    required this.scrollableContent,
    required this.fixedActions,
  });

  @override
  Widget build(BuildContext context) {
    // YÊU CẦU 4.1: Widget gốc là ClipRRect để bo góc
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      // YÊU CẦU 4.2: Lớp Hiệu ứng Mờ
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        // YÊU CẦU 4.3: Lớp Nền
        child: Container(
          decoration: BoxDecoration(
            // Màu nền bán trong suốt để hiệu ứng mờ có thể nhìn thấy được
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.25),
            // Thêm một đường viền nhẹ ở trên để tạo cảm giác tách biệt
            border: Border(
              // ignore: deprecated_member_use
              top: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          // YÊU CẦU 4.4: Bố cục Flexbox bằng Column
          child: Column(
            // Các widget con sẽ được sắp xếp theo chiều dọc
            children: [
              // Con đầu tiên: Vùng nội dung cuộn
              Expanded(
                // Expanded sẽ chiếm hết không gian dọc còn lại,
                // đẩy vùng hành động xuống dưới cùng.
                child: scrollableContent,
              ),
              // Con thứ hai: Vùng hành động cố định
              // Widget này không được bọc trong Expanded, do đó nó sẽ
              // giữ nguyên kích thước của mình và nằm ở dưới.
              fixedActions,
            ],
          ),
        ),
      ),
    );
  }
}