// comment.dart - Updated for Like System

import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String articleId;
  final String? parentId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String text;
  final String? replyingToUserName;
  final Timestamp timestamp;
  final int likeCount; // Thay thế upvotes/downvotes
  final int replyCount;
  final bool isEdited;

  const Comment({
    required this.id,
    required this.articleId,
    this.parentId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.text,
    this.replyingToUserName,
    required this.timestamp,
    this.likeCount = 0, // Thay thế upvotes/downvotes
    this.replyCount = 0,
    this.isEdited = false,
  });

  // Chuyển đổi từ Firestore DocumentSnapshot sang đối tượng Comment
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Comment(
      id: doc.id,
      articleId: data['articleId'] ?? '',
      parentId: data['parentId'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatarUrl: data['userAvatarUrl'],
      text: data['text'] ?? '',
      replyingToUserName: data['replyingToUserName'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likeCount: data['likeCount'] ?? 0, // Thay thế upvotes/downvotes
      replyCount: data['replyCount'] ?? 0,
      isEdited: data['isEdited'] ?? false,
    );
  }

  // Chuyển đổi Comment thành Map để lưu vào Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'articleId': articleId,
      'parentId': parentId,
      'userId': userId,
      'userName': userName,
      'userAvatarUrl': userAvatarUrl,
      'text': text,
      'replyingToUserName': replyingToUserName,
      'timestamp': timestamp,
      'likeCount': likeCount, // Thay thế upvotes/downvotes
      'replyCount': replyCount,
      'isEdited': isEdited,
    };
  }

  Comment copyWith({
    String? id,
    String? articleId,
    String? parentId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? text,
    String? replyingToUserName,
    Timestamp? timestamp,
    int? likeCount, // Thay thế upvotes/downvotes
    int? replyCount,
    bool? isEdited,
  }) {
    return Comment(
      id: id ?? this.id,
      articleId: articleId ?? this.articleId,
      parentId: parentId ?? this.parentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      text: text ?? this.text,
      replyingToUserName: replyingToUserName ?? this.replyingToUserName,
      timestamp: timestamp ?? this.timestamp,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}