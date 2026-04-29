import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionModel {
  final String submissionId;
  final String userId;
  final String challengeId;
  final String challengeTitle;
  final String challengeDate; // YYYY-MM-DD, denormalized for feed filtering
  final String username;
  final String userPhotoUrl;
  final String photoUrl;
  final String caption;
  final int voteCount;
  final int commentsCount;
  final int reportCount;
  final bool isHidden;
  final Timestamp submittedAt;

  const SubmissionModel({
    required this.submissionId,
    required this.userId,
    required this.challengeId,
    this.challengeTitle = '',
    this.challengeDate = '',
    required this.username,
    required this.userPhotoUrl,
    required this.photoUrl,
    required this.caption,
    required this.voteCount,
    this.commentsCount = 0,
    required this.reportCount,
    required this.isHidden,
    required this.submittedAt,
  });

  factory SubmissionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubmissionModel(
      submissionId: id,
      userId: map['user_id'] as String? ?? '',
      challengeId: map['challenge_id'] as String? ?? '',
      challengeTitle: map['challenge_title'] as String? ?? '',
      challengeDate: map['challenge_date'] as String? ?? '',
      username: map['username'] as String? ?? '',
      userPhotoUrl: map['user_photo_url'] as String? ?? '',
      photoUrl: map['photo_url'] as String? ?? '',
      caption: map['caption'] as String? ?? '',
      voteCount: map['vote_count'] as int? ?? 0,
      commentsCount: map['comments_count'] as int? ?? 0,
      reportCount: map['report_count'] as int? ?? 0,
      isHidden: map['is_hidden'] as bool? ?? false,
      submittedAt: map['submitted_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'submission_id': submissionId,
      'user_id': userId,
      'challenge_id': challengeId,
      'challenge_title': challengeTitle,
      'challenge_date': challengeDate,
      'username': username,
      'user_photo_url': userPhotoUrl,
      'photo_url': photoUrl,
      'caption': caption,
      'vote_count': voteCount,
      'comments_count': commentsCount,
      'report_count': reportCount,
      'is_hidden': isHidden,
      'submitted_at': submittedAt,
    };
  }

  SubmissionModel copyWith({
    String? submissionId,
    String? userId,
    String? challengeId,
    String? challengeTitle,
    String? challengeDate,
    String? username,
    String? userPhotoUrl,
    String? photoUrl,
    String? caption,
    int? voteCount,
    int? commentsCount,
    int? reportCount,
    bool? isHidden,
    Timestamp? submittedAt,
  }) {
    return SubmissionModel(
      submissionId: submissionId ?? this.submissionId,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      challengeDate: challengeDate ?? this.challengeDate,
      username: username ?? this.username,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      caption: caption ?? this.caption,
      voteCount: voteCount ?? this.voteCount,
      commentsCount: commentsCount ?? this.commentsCount,
      reportCount: reportCount ?? this.reportCount,
      isHidden: isHidden ?? this.isHidden,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}