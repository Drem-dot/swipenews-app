// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/article.dart';

// Một lớp trợ giúp để đóng gói kết quả trả về, giúp code dễ đọc hơn
class PaginatedArticles {
  final List<Article> articles;
  final DocumentSnapshot? lastDocument;

  PaginatedArticles({required this.articles, this.lastDocument});
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int _defaultLimit = 10; // Số bài báo tải mỗi lần

  //====================================================================
  // VÙNG QUẢN LÝ BÀI BÁO (Articles)
  //====================================================================

  /// YÊU CẦU 1.4: Cập nhật getArticles để hỗ trợ pagination
  Future<PaginatedArticles> getArticles({DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _db
          .collection('articles')
          .where('status', isEqualTo: 'processed')
          .orderBy('created_at', descending: true)
          .limit(_defaultLimit);

      // Nếu có lastDocument, bắt đầu truy vấn từ sau nó
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final articles = querySnapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();

      return PaginatedArticles(
        articles: articles,
        // Lấy document cuối cùng của trang này để làm cursor cho trang sau
        lastDocument: querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null,
      );
    } catch (e) {
      debugPrint("Lỗi khi lấy bài báo: $e");
      return PaginatedArticles(articles: [], lastDocument: null);
    }
  }

  /// YÊU CẦU 1.3: Cập nhật getPersonalizedArticles để hỗ trợ pagination
  Future<PaginatedArticles> getPersonalizedArticles({
    required List<String> categories,
    required Set<String> viewedIds,
    DocumentSnapshot? lastDocument,
  }) async {
    if (categories.isEmpty) {
      return PaginatedArticles(articles: [], lastDocument: null);
    }

    try {
      Query query = _db
          .collection('articles')
          .where('status', isEqualTo: 'processed')
          .where('category', whereIn: categories)
          .orderBy('created_at', descending: true) // Bắt buộc phải có orderBy khi dùng cursor
          .limit(30); // Lấy nhiều hơn để có cái mà lọc

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      final articles = querySnapshot.docs
          .map((doc) => Article.fromFirestore(doc))
          .where((article) => !viewedIds.contains(article.id))
          .toList();

      articles.shuffle();

      return PaginatedArticles(
        articles: articles.take(_defaultLimit).toList(), // Giới hạn số lượng trả về
        lastDocument: querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null,
      );
    } catch (e) {
      debugPrint("Lỗi khi lấy bài báo cá nhân hóa: $e");
      return PaginatedArticles(articles: [], lastDocument: null);
    }
  }
  
  //====================================================================
  // VÙNG QUẢN LÝ TƯƠNG TÁC NGƯỜI DÙNG (User Interactions)
  //====================================================================

  Future<void> toggleSaveArticle(String userId, Article article) async {
    DocumentReference docRef = _db.collection('users').doc(userId).collection('saved_articles').doc(article.id);
    try {
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set(article.toJson());
      }
    } catch (e) {
      debugPrint("Lỗi khi toggleSaveArticle: $e");
      rethrow;
    }
  }

  Future<Set<String>> getSavedArticleIds(String userId) async {
    try {
      QuerySnapshot snapshot = await _db.collection('users').doc(userId).collection('saved_articles').get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      debugPrint("Lỗi khi getSavedArticleIds: $e");
      return {};
    }
  }

  Stream<List<Article>> getSavedArticlesStream(String userId) {
    final snapshots = _db
        .collection('users')
        .doc(userId)
        .collection('saved_articles')
        .orderBy('created_at', descending: true)
        .snapshots();
    return snapshots.map((querySnapshot) {
      return querySnapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
    });
  }

  Future<void> toggleLikeArticle(String userId, Article article) async {
    DocumentReference docRef = _db.collection('users').doc(userId).collection('liked_articles').doc(article.id);
    try {
      final doc = await docRef.get();
      if (doc.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'id': article.id,
          'category': article.category,
          'likedAt': FieldValue.serverTimestamp()
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi toggleLikeArticle: $e");
      rethrow;
    }
  }

  Future<Set<String>> getLikedArticleIds(String userId) async {
    try {
      QuerySnapshot snapshot = await _db.collection('users').doc(userId).collection('liked_articles').get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      debugPrint("Lỗi khi getLikedArticleIds: $e");
      return {};
    }
  }

  Future<List<String>> getLikedCategories(String userId) async {
    try {
      final snapshot = await _db.collection('users').doc(userId).collection('liked_articles').get();
      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String?)
          .where((category) => category != null)
          .cast<String>()
          .toList();
      return categories;
    } catch (e) {
      debugPrint("Lỗi khi lấy danh mục đã thích: $e");
      return [];
    }
  }

  Future<void> logViewedArticle(String userId, String articleId) async {
    DocumentReference docRef = _db.collection('users').doc(userId).collection('viewed_articles').doc(articleId);
    try {
      await docRef.set({'viewedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint("Lỗi khi ghi log bài báo đã xem: $e");
    }
  }

  Future<Set<String>> getViewedArticleIds(String userId) async {
    try {
      final snapshot = await _db.collection('users').doc(userId).collection('viewed_articles').get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      debugPrint("Lỗi khi lấy ID bài báo đã xem: $e");
      return {};
    }
  }
  
}