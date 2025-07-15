// lib/providers/for_you_feed_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/firestore_service.dart';
// Đã xóa bỏ import 'package:collection/collection.dart'

class ForYouFeedProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  List<Article> articles = [];
  bool isLoading = false;

  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  List<String> _likedCategories = [];

  Future<void> updateUser(User? newUser) async {
    if (newUser != null && _user != newUser) {
      _user = newUser;
      isLoading = true;
      notifyListeners();
      _likedCategories = await _firestoreService.getLikedCategories(_user!.uid);
      await fetchForYouFeed();
    }
  }

  void registerLike(String category) {
    if (category.isNotEmpty) {
      _likedCategories.add(category);
      fetchForYouFeed();
    }
  }

  // Hàm private để tính toán sở thích
  List<String> _calculateFavorites() {
    if (_likedCategories.isEmpty) return [];

    // SỬA LỖI Ở ĐÂY: Triển khai logic đếm thủ công bằng Map
    final Map<String, int> categoryCounts = {};
    for (final category in _likedCategories) {
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    final sortedEntries = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(3).map((entry) => entry.key).toList();
  }

  Future<void> fetchForYouFeed() async {
    if (_user == null) return;
    
    isLoading = true;
    _hasMore = true;
    _lastDocument = null;
    articles = [];
    // Không gọi notifyListeners() ở đây để tránh FOUC (flash of unstyled content)
    // Sẽ gọi ở cuối hàm khi có dữ liệu hoặc lỗi.

    final favoriteCategories = _calculateFavorites();
    if (favoriteCategories.isEmpty) {
      isLoading = false; 
      notifyListeners(); 
      return;
    }

    final viewedIds = await _firestoreService.getViewedArticleIds(_user!.uid);
    final result = await _firestoreService.getPersonalizedArticles(
      categories: favoriteCategories,
      viewedIds: viewedIds,
      lastDocument: null,
    );

    articles = result.articles;
    _lastDocument = result.lastDocument;
    if (result.articles.length < 10) {
      _hasMore = false;
    }

    isLoading = false;
    notifyListeners();
  }
  
  Future<void> fetchMoreForYouFeed() async {
    if (_isLoadingMore || !_hasMore || _user == null) return;

    _isLoadingMore = true;
    notifyListeners();
    
    final favoriteCategories = _calculateFavorites();
    if (favoriteCategories.isEmpty) {
      _isLoadingMore = false; 
      notifyListeners(); 
      return;
    }
    
    final viewedIds = await _firestoreService.getViewedArticleIds(_user!.uid);

    final result = await _firestoreService.getPersonalizedArticles(
      categories: favoriteCategories,
      viewedIds: viewedIds,
      lastDocument: _lastDocument,
    );
    
    articles.addAll(result.articles);
    _lastDocument = result.lastDocument;
    if (result.articles.length < 10) {
      _hasMore = false;
    }

    _isLoadingMore = false;
    notifyListeners();
  }
}