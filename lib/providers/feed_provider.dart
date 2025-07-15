// lib/providers/feed_provider.dart

import 'dart:async';
// YÊU CẦU 1: Thêm import còn thiếu
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipenews/providers/for_you_feed_provider.dart';

import '../models/article.dart';
import '../services/firestore_service.dart';

class FeedProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  List<Article> articles = [];
  bool isLoading = false;
  
  // Lớp DocumentSnapshot giờ đã được nhận dạng
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  
  Set<String> savedArticleIds = {};
  Set<String> likedArticleIds = {};
  Timer? _viewedLogTimer;
  int _currentPage = 0;

  void updateUser(User? newUser) {
    if (_user != newUser) {
      _user = newUser;
      fetchArticles();
    }
  }

  Future<void> fetchArticles() async {
    isLoading = true;
    _hasMore = true;
    _lastDocument = null;
    articles = [];
    notifyListeners();

    final result = await _firestoreService.getArticles(lastDocument: null);
    articles = result.articles;
    _lastDocument = result.lastDocument;
    
    if (result.articles.length < 10) {
      _hasMore = false;
    }

    if (_user != null) {
      final userId = _user!.uid;
      savedArticleIds = await _firestoreService.getSavedArticleIds(userId);
      likedArticleIds = await _firestoreService.getLikedArticleIds(userId);
    }
    
    isLoading = false;
    notifyListeners();
  }
  
  Future<void> fetchMoreArticles() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    final result = await _firestoreService.getArticles(lastDocument: _lastDocument);

    articles.addAll(result.articles);
    _lastDocument = result.lastDocument;

    if (result.articles.length < 10) {
      _hasMore = false;
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> toggleSave(Article article) async {
    if (_user == null) return;
    if (savedArticleIds.contains(article.id)) {
      savedArticleIds.remove(article.id);
    } else {
      savedArticleIds.add(article.id);
    }
    notifyListeners();
    await _firestoreService.toggleSaveArticle(_user!.uid, article);
  }

Future<void> toggleLike(BuildContext context, Article article) async {
  if (_user == null) return;
  final String userId = _user!.uid;

  if (likedArticleIds.contains(article.id)) {
    likedArticleIds.remove(article.id);
  } else {
    likedArticleIds.add(article.id);
    context.read<ForYouFeedProvider>().registerLike(article.category);
  }
  notifyListeners();
  
  // XÁC NHẬN: Lời gọi này đang truyền vào cả đối tượng 'article',
  // điều này là chính xác với chữ ký hàm mới.
  await _firestoreService.toggleLikeArticle(userId, article);
}

  void onPageChanged(int newPage) {
    _currentPage = newPage;
    _viewedLogTimer?.cancel();
    _viewedLogTimer = Timer(const Duration(seconds: 2), () {
      if (_user != null && articles.isNotEmpty && _currentPage < articles.length) {
        final articleId = articles[_currentPage].id;
        _firestoreService.logViewedArticle(_user!.uid, articleId);
      }
    });
  }

  @override
  void dispose() {
    _viewedLogTimer?.cancel();
    super.dispose();
  }
}