import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String submissionId;
  final String userId;
  final String username;
  final String userPhotoUrl;
  final String body;
  final Timestamp createdAt;

  const CommentModel({
    required this.commentId,
    required this.submissionId,
    required this.userId,
    required this.username,
    required this.userPhotoUrl,
    required this.body,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      commentId: id,
      submissionId: map['submission_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      username: map['username'] as String? ?? '',
      userPhotoUrl: map['user_photo_url'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: map['created_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'submission_id': submissionId,
      'user_id': userId,
      'username': username,
      'user_photo_url': userPhotoUrl,
      'body': body,
      'created_at': createdAt,
    };
  }
}