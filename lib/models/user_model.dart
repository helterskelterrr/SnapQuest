import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String username;
  final String email;
  final String photoUrl;
  final String bio;
  final int totalXp;
  final String rank;
  final int weeklyPoints;
  final int dailyVotesGiven;
  final int dailyReportsRemaining;
  final String lastVoteResetDate;
  final Timestamp createdAt;

  const UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.photoUrl,
    this.bio = '',
    required this.totalXp,
    required this.rank,
    required this.weeklyPoints,
    required this.dailyVotesGiven,
    required this.dailyReportsRemaining,
    required this.lastVoteResetDate,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] as String? ?? '',
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photo_url'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      totalXp: map['total_xp'] as int? ?? 0,
      rank: map['rank'] as String? ?? 'Rookie Snapper',
      weeklyPoints: map['weekly_points'] as int? ?? 0,
      dailyVotesGiven: map['daily_votes_given'] as int? ?? 0,
      dailyReportsRemaining: map['daily_reports_remaining'] as int? ?? 3,
      lastVoteResetDate: map['last_vote_reset_date'] as String? ?? '',
      createdAt: map['created_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'photo_url': photoUrl,
      'bio': bio,
      'total_xp': totalXp,
      'rank': rank,
      'weekly_points': weeklyPoints,
      'daily_votes_given': dailyVotesGiven,
      'daily_reports_remaining': dailyReportsRemaining,
      'last_vote_reset_date': lastVoteResetDate,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    String? userId,
    String? username,
    String? email,
    String? photoUrl,
    String? bio,
    int? totalXp,
    String? rank,
    int? weeklyPoints,
    int? dailyVotesGiven,
    int? dailyReportsRemaining,
    String? lastVoteResetDate,
    Timestamp? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      totalXp: totalXp ?? this.totalXp,
      rank: rank ?? this.rank,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      dailyVotesGiven: dailyVotesGiven ?? this.dailyVotesGiven,
      dailyReportsRemaining: dailyReportsRemaining ?? this.dailyReportsRemaining,
      lastVoteResetDate: lastVoteResetDate ?? this.lastVoteResetDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
