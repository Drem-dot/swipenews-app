// lib/models/article.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id; // YÊU CẦU 2: Thêm trường id
  final String title;
  final String content;
  final String summary;
  final String sourceUrl;
  final String? imageUrl;
  final String? author;
  final String category;
  final DateTime createdAt;

  Article({
    required this.id, // YÊU CẦU 3: Cập nhật hàm khởi tạo
    required this.title,
    required this.content,
    required this.summary,
    required this.sourceUrl,
    this.imageUrl,
    this.author,
    required this.category,
    required this.createdAt,
  });

  factory Article.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Article(
      id: doc.id, // YÊU CẦU 3: Lấy id từ document snapshot
      title: data['title'] ?? 'Không có tiêu đề',
      content: data['content'] ?? '',
      summary: data['summary'] ?? '',
      sourceUrl: data['source_url'] ?? '',
      imageUrl: data['image_url'],
      author: data['author'],
      category: data['category'] ?? 'Chung',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  // YÊU CẦU 4: Thêm hàm toJson
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'summary': summary,
      'source_url': sourceUrl,
      'image_url': imageUrl,
      'author': author,
      'category': category,
      'created_at': Timestamp.fromDate(createdAt), // Chuyển ngược lại thành Timestamp
    };
  }
}