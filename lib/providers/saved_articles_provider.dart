// lib/providers/saved_articles_provider.dart

import 'dart:async'; // Cần thiết cho StreamSubscription
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/firestore_service.dart';

class SavedArticlesProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  List<Article> savedArticles = []; // Không cần private nữa
  
  // YÊU CẦU 2.3: Thêm biến để quản lý stream
  StreamSubscription? _savedArticlesSubscription;

  void updateUser(User? newUser) {
    if (_user != newUser) {
      _user = newUser;
      if (_user != null) {
        // Gọi hàm lắng nghe mới
        listenToSavedArticles(_user!.uid);
      } else {
        // Nếu người dùng đăng xuất, hủy stream và xóa dữ liệu
        _savedArticlesSubscription?.cancel();
        savedArticles = [];
        notifyListeners();
      }
    }
  }

  // YÊU CẦU 2.4: Hàm mới để lắng nghe stream
  void listenToSavedArticles(String userId) {
    _savedArticlesSubscription?.cancel(); // Hủy kết nối cũ trước khi tạo mới
    _savedArticlesSubscription = _firestoreService
        .getSavedArticlesStream(userId)
        .listen((articles) {
          savedArticles = articles;
          notifyListeners(); // Cập nhật UI mỗi khi có dữ liệu mới
    });
  }

  // YÊU CẦU 2.5: Dọn dẹp subscription khi provider bị hủy
  @override
  void dispose() {
    _savedArticlesSubscription?.cancel();
    super.dispose();
  }
}