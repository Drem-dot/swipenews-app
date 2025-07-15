// lib/screens/article_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/article.dart';

class ArticleDetailScreen extends StatelessWidget {
  // Yêu cầu 3: Nhận một đối tượng Article
  final Article article;
  
  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    // Yêu cầu 4: Widget gốc là Scaffold
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // AppBar đơn giản, tự động có nút back
        title: Text(
          article.category.toUpperCase(),
          style: const TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1, // Thêm một đường kẻ mờ dưới AppBar
        iconTheme: const IconThemeData(color: Colors.black), // Đảm bảo nút back màu đen
      ),
      // Body có thể cuộn
      body: SingleChildScrollView(
        // Padding cho toàn bộ nội dung
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề bài báo
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            // Tên tác giả
            Text(
              'Tác giả: ${article.author ?? "Không rõ"}',
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            // Nội dung bài báo, có thể chọn và sao chép
            SelectableText(
              article.content,
              style: const TextStyle(
                fontSize: 17,
                height: 1.6, // Chiều cao dòng để dễ đọc
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}