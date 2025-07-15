// comment_provider.dart - Updated for Like System with Optimistic Updates

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comment_service.dart';
import '../models/comment.dart';

class CommentProvider with ChangeNotifier {
  final CommentService _commentService = CommentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache streams to prevent recreating
  final Map<String, Stream<List<Comment>>> _commentStreamsCache = {};
  final Map<String, Stream<List<Comment>>> _repliesStreamsCache = {};

  final bool _isPosting = false;
  bool get isPosting => _isPosting;

  // Lưu trữ trạng thái like của người dùng
  final Map<String, bool> _userLikes = {}; // key: commentId, value: true/false
  Map<String, bool> get userLikes => _userLikes;

  // Thêm biến để lưu trữ trạng thái like tạm thời cho optimistic updates
  final Map<String, int> _temporaryLikeChanges = {};

  // Optimistic replies storage
  final Map<String, List<Comment>> _optimisticReplies = {};

  // ============ USER INFO METHODS ============
  String? getCurrentUserId() => _auth.currentUser?.uid;
  String? getCurrentUserName() => _auth.currentUser?.displayName ?? 'Anonymous';
  String? getCurrentUserAvatar() => _auth.currentUser?.photoURL;

  // ============ COMMENT STREAMS ============
  // Optimized getCommentsStream with caching
  Stream<List<Comment>> getCommentsStream(String articleId) {
    // Return cached stream if exists
    if (_commentStreamsCache.containsKey(articleId)) {
      return _commentStreamsCache[articleId]!;
    }

    // Create and cache new stream
    final stream = _commentService.getRootCommentsStream(articleId)
        .distinct(); // Prevent duplicate emissions
    
    _commentStreamsCache[articleId] = stream;
    return stream;
  }

  // Optimized getRepliesStream with caching
  Stream<List<Comment>> getRepliesStream(String articleId, String parentId) {
    final key = '$articleId-$parentId';
    
    if (_repliesStreamsCache.containsKey(key)) {
      return _repliesStreamsCache[key]!;
    }

    final stream = _commentService.getRepliesStream(articleId, parentId)
        .distinct();
    
    _repliesStreamsCache[key] = stream;
    return stream;
  }

  // ============ LIKE SYSTEM ============
  
  // Load user likes for comments
  Future<void> loadUserLikesForComments(String articleId, List<String> commentIds) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || commentIds.isEmpty) return;

   
      final likes = await _commentService.batchLoadUserLikes(
        articleId: articleId,
        commentIds: commentIds,
        userId: userId,
      );
      
      _userLikes.addAll(likes);
      // Only notify if there are actual changes
      if (likes.isNotEmpty) {
        notifyListeners();
      
    } 
  }

  // Check if comment is liked by current user
  bool isCommentLiked(String commentId) {
    return _userLikes[commentId] ?? false;
  }

  // Get comment like count (with optimistic updates)
  int getCommentLikeCount(String commentId) {
    // This will be used with actual comment data in the UI
    // The temporary changes are applied in the widget
    return _temporaryLikeChanges[commentId] ?? 0;
  }

  // Get adjusted like count for a comment
  int getAdjustedLikeCount(Comment comment) {
    final baseCount = comment.likeCount;
    final tempChange = _temporaryLikeChanges[comment.id] ?? 0;
    return baseCount + tempChange;
  }


Future<void> toggleLike({
  required String articleId,
  required String commentId,
  String? parentCommentId,
}) async {
  final userId = _auth.currentUser?.uid;
  if (userId == null) return;

  try {
    await _commentService.toggleLike(
      articleId: articleId,
      commentId: commentId,
      userId: userId,
      isLiked: !(_userLikes[commentId] ?? false),
      parentCommentId: parentCommentId,
    );
    
    // Update local cache silently without notifying
    _userLikes[commentId] = !(_userLikes[commentId] ?? false);
    // DON'T call notifyListeners() here
  } catch (e) {
    rethrow;
  }
}
  // Add optimistic reply
  void addOptimisticReply(Comment reply) {
    final parentId = reply.parentId!;
    if (_optimisticReplies[parentId] == null) {
      _optimisticReplies[parentId] = [];
    }
    _optimisticReplies[parentId]!.add(reply);
    notifyListeners();
  }

  // Remove optimistic reply
  void removeOptimisticReply(String replyId) {
    _optimisticReplies.forEach((parentId, replies) {
      replies.removeWhere((reply) => reply.id == replyId);
    });
    notifyListeners();
  }

  // Get merged replies (real + optimistic)
  List<Comment> getMergedReplies(String parentId, List<Comment> realReplies) {
    final optimisticReplies = _optimisticReplies[parentId] ?? [];
    final allReplies = [...realReplies, ...optimisticReplies];
    
    // Sort by timestamp
    allReplies.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return allReplies;
  }

  // ============ COMMENT POSTING ============
  
  // Add comment without notifyListeners
  Future<void> addComment({
    required String articleId,
    required String text,
    String? parentId,
    String? replyingToUserName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final Timestamp now = Timestamp.now();

    final Comment comment = Comment(
      id: id,
      articleId: articleId,
      parentId: parentId,
      userId: currentUser.uid,
      userName: currentUser.displayName ?? 'Anonymous',
      userAvatarUrl: currentUser.photoURL,
      text: text,
      replyingToUserName: replyingToUserName,
      timestamp: now,
      likeCount: 0,
      replyCount: 0,
      isEdited: false,
    );

    if (parentId == null) {
      await _commentService.postComment(articleId, comment);
    } else {
      await _commentService.postReply(articleId, parentId, comment);
    }
    
    // DON'T call notifyListeners() - let stream handle updates
  }

  // Legacy method - kept for backward compatibility
  Future<void> postComment({
    required String articleId,
    required String text,
    required User currentUser,
    String? parentId,
    String? replyingToUserName,
  }) async {
    await addComment(
      articleId: articleId,
      text: text,
      parentId: parentId,
      replyingToUserName: replyingToUserName,
    );
  }

  // ============ COMMENT MANAGEMENT ============
  
  // Delete comment
  Future<void> deleteComment(
      String articleId, String commentId,
      {String? parentCommentId}) async {
    try {
      await _commentService.deleteComment(
        articleId,
        commentId,
        parentCommentId: parentCommentId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Update comment
  Future<void> updateComment(
      String articleId, String commentId, String newText,
      {String? parentCommentId}) async {
    try {
      await _commentService.updateComment(
        articleId,
        commentId,
        newText,
        parentCommentId: parentCommentId,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ============ CLEANUP ============
  
  @override
  void dispose() {
    _commentStreamsCache.clear();
    _repliesStreamsCache.clear();
    _userLikes.clear();
    _temporaryLikeChanges.clear();
    _optimisticReplies.clear();
    super.dispose();
  }
}