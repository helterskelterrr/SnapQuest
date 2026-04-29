import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/challenge_model.dart';
import '../models/submission_model.dart';
import '../models/comment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// SupabaseService mirrors all CRUD operations to Supabase PostgreSQL.
/// Firebase (Firestore) remains the source of truth for realtime streams.
/// Supabase is used for relational queries and academic CRUD requirements.
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;

  // ─────────────────────────────────────────
  // USERS
  // ─────────────────────────────────────────

  /// CREATE: Insert user baru ke Supabase
  Future<void> createUser({
    required String uid,
    required String username,
    required String email,
    required String photoUrl,
    String bio = '',
  }) async {
    await _db.from('users').upsert({
      'id': uid,
      'username': username,
      'username_lower': username.toLowerCase(),
      'email': email,
      'photo_url': photoUrl,
      'bio': bio,
      'total_xp': 0,
      'weekly_points': 0,
      'rank': 'Rookie Snapper',
    });
  }

  /// READ: Ambil satu user berdasarkan UID
  Future<UserModel?> getUser(String uid) async {
    final res = await _db
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (res == null) return null;
    return _userFromRow(res);
  }

  /// READ: Cari user berdasarkan prefix username
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final lower = query.trim().toLowerCase();
    final res = await _db
        .from('users')
        .select()
        .ilike('username_lower', '$lower%')
        .limit(20);
    return (res as List).map((row) => _userFromRow(row)).toList();
  }

  /// READ: Leaderboard mingguan
  Future<List<UserModel>> getWeeklyLeaderboard({int limit = 20}) async {
    final res = await _db
        .from('users')
        .select()
        .order('weekly_points', ascending: false)
        .limit(limit);
    return (res as List).map((row) => _userFromRow(row)).toList();
  }

  /// READ: Leaderboard all-time
  Future<List<UserModel>> getAllTimeLeaderboard({int limit = 20}) async {
    final res = await _db
        .from('users')
        .select()
        .order('total_xp', ascending: false)
        .limit(limit);
    return (res as List).map((row) => _userFromRow(row)).toList();
  }

  /// UPDATE: Update profil user
  Future<void> updateUserProfile({
    required String uid,
    required String username,
    required String photoUrl,
    String? bio,
  }) async {
    final data = <String, dynamic>{
      'username': username,
      'username_lower': username.toLowerCase(),
      'photo_url': photoUrl,
    };
    if (bio != null) data['bio'] = bio;
    await _db.from('users').update(data).eq('id', uid);
  }

  /// UPDATE: Increment XP dan weekly points user
  Future<void> incrementUserXp(String uid, {int xp = 2}) async {
    final current = await getUser(uid);
    if (current == null) return;
    await _db.from('users').update({
      'total_xp': current.totalXp + xp,
      'weekly_points': current.weeklyPoints + xp,
    }).eq('id', uid);
  }

  /// UPDATE: Decrement XP dan weekly points user
  Future<void> decrementUserXp(String uid, {int xp = 2}) async {
    final current = await getUser(uid);
    if (current == null) return;
    await _db.from('users').update({
      'total_xp': (current.totalXp - xp).clamp(0, 999999),
      'weekly_points': (current.weeklyPoints - xp).clamp(0, 999999),
    }).eq('id', uid);
  }

  /// DELETE: Hapus user (admin only)
  Future<void> deleteUser(String uid) async {
    await _db.from('users').delete().eq('id', uid);
  }

  // ─────────────────────────────────────────
  // CHALLENGES
  // ─────────────────────────────────────────

  /// CREATE: Buat challenge baru
  Future<void> createChallenge({
    required String title,
    required String description,
    required String date,
    String? createdBy,
  }) async {
    await _db.from('challenges').insert({
      'title': title,
      'description': description,
      'date': date,
      if (createdBy != null) 'created_by': createdBy,
    });
  }

  /// READ: Ambil challenge untuk tanggal tertentu
  Future<ChallengeModel?> getChallengeByDate(String date) async {
    final res = await _db
        .from('challenges')
        .select()
        .eq('date', date)
        .maybeSingle();
    if (res == null) return null;
    return _challengeFromRow(res);
  }

  /// READ: Ambil semua challenges
  Future<List<ChallengeModel>> getAllChallenges() async {
    final res = await _db
        .from('challenges')
        .select()
        .order('date', ascending: false);
    return (res as List).map((row) => _challengeFromRow(row)).toList();
  }

  /// UPDATE: Update challenge
  Future<void> updateChallenge(
    String challengeId, {
    String? title,
    String? description,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    await _db.from('challenges').update(data).eq('id', challengeId);
  }

  /// DELETE: Hapus challenge
  Future<void> deleteChallenge(String challengeId) async {
    await _db.from('challenges').delete().eq('id', challengeId);
  }

  // ─────────────────────────────────────────
  // SUBMISSIONS
  // ─────────────────────────────────────────

  /// CREATE: Simpan submission baru
  Future<void> createSubmission(SubmissionModel s) async {
    // Cari challenge_id di Supabase berdasarkan challenge_id dari Firestore
    await _db.from('submissions').upsert({
      'id': s.submissionId,
      'user_id': s.userId,
      'challenge_id': s.challengeId,
      'photo_url': s.photoUrl,
      'caption': s.caption,
      'vote_count': s.voteCount,
    });
  }

  /// READ: Ambil semua submissions untuk sebuah challenge
  Future<List<SubmissionModel>> getSubmissionsByChallenge(
      String challengeId) async {
    final res = await _db
        .from('submissions')
        .select('*, users(username, photo_url)')
        .eq('challenge_id', challengeId)
        .order('vote_count', ascending: false);
    return (res as List).map((row) => _submissionFromRow(row)).toList();
  }

  /// READ: Ambil semua submissions milik user
  Future<List<SubmissionModel>> getSubmissionsByUser(String userId) async {
    final res = await _db
        .from('submissions')
        .select('*, users(username, photo_url)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (res as List).map((row) => _submissionFromRow(row)).toList();
  }

  /// READ: Cek apakah user sudah submit untuk challenge ini
  Future<bool> hasSubmitted(String userId, String challengeId) async {
    final res = await _db
        .from('submissions')
        .select('id')
        .eq('user_id', userId)
        .eq('challenge_id', challengeId)
        .maybeSingle();
    return res != null;
  }

  /// UPDATE: Update vote count submission
  Future<void> updateSubmissionVoteCount(
      String submissionId, int voteCount) async {
    await _db
        .from('submissions')
        .update({'vote_count': voteCount})
        .eq('id', submissionId);
  }

  /// DELETE: Hapus submission
  Future<void> deleteSubmission(String submissionId) async {
    await _db.from('submissions').delete().eq('id', submissionId);
  }

  // ─────────────────────────────────────────
  // VOTES
  // ─────────────────────────────────────────

  /// CREATE: Tambah vote
  Future<void> createVote({
    required String voterId,
    required String submissionId,
  }) async {
    await _db.from('votes').upsert({
      'voter_id': voterId,
      'submission_id': submissionId,
    });
    // Increment vote_count di submissions
    final sub = await _db
        .from('submissions')
        .select('vote_count')
        .eq('id', submissionId)
        .maybeSingle();
    final currentVotes = sub?['vote_count'] as int?;
    if (currentVotes != null) {
      await _db.from('submissions').update({
        'vote_count': currentVotes + 1,
      }).eq('id', submissionId);
    }
  }

  /// READ: Cek apakah user sudah vote submission ini
  Future<bool> hasVoted(String voterId, String submissionId) async {
    final res = await _db
        .from('votes')
        .select('id')
        .eq('voter_id', voterId)
        .eq('submission_id', submissionId)
        .maybeSingle();
    return res != null;
  }

  /// READ: Ambil semua submission yang sudah di-vote user
  Future<Set<String>> getVotedSubmissionIds(String voterId) async {
    final res = await _db
        .from('votes')
        .select('submission_id')
        .eq('voter_id', voterId);
    return (res as List)
        .map((row) => row['submission_id'] as String)
        .toSet();
  }

  /// DELETE: Hapus vote (unvote)
  Future<void> deleteVote({
    required String voterId,
    required String submissionId,
  }) async {
    await _db
        .from('votes')
        .delete()
        .eq('voter_id', voterId)
        .eq('submission_id', submissionId);
    // Decrement vote_count di submissions
    final sub = await _db
        .from('submissions')
        .select('vote_count')
        .eq('id', submissionId)
        .maybeSingle();
    final currentVotes = sub?['vote_count'] as int?;
    if (currentVotes != null) {
      await _db.from('submissions').update({
        'vote_count': (currentVotes - 1).clamp(0, 999999),
      }).eq('id', submissionId);
    }
  }

  // ─────────────────────────────────────────
  // COMMENTS
  // ─────────────────────────────────────────

  /// CREATE: Tambah komentar baru
  Future<void> addComment({
    required String userId,
    required String submissionId,
    required String content,
  }) async {
    await _db.from('comments').insert({
      'user_id': userId,
      'submission_id': submissionId,
      'content': content,
    });
  }

  /// READ: Ambil semua komentar untuk sebuah submission (dengan JOIN ke users)
  Future<List<CommentModel>> getComments(String submissionId) async {
    final res = await _db
        .from('comments')
        .select('*, users(username, photo_url)')
        .eq('submission_id', submissionId)
        .order('created_at', ascending: true);
    return (res as List).map((row) => _commentFromRow(row)).toList();
  }

  /// DELETE: Hapus komentar
  Future<void> deleteComment(String commentId) async {
    await _db.from('comments').delete().eq('id', commentId);
  }

  // ─────────────────────────────────────────
  // REPORTS
  // ─────────────────────────────────────────

  /// CREATE: Laporkan submission
  Future<void> createReport({
    required String reporterId,
    required String submissionId,
    required String reason,
  }) async {
    await _db.from('reports').upsert({
      'reporter_id': reporterId,
      'submission_id': submissionId,
      'reason': reason,
    });
  }

  /// READ: Cek apakah user sudah melaporkan submission
  Future<bool> hasReported(String reporterId, String submissionId) async {
    final res = await _db
        .from('reports')
        .select('id')
        .eq('reporter_id', reporterId)
        .eq('submission_id', submissionId)
        .maybeSingle();
    return res != null;
  }

  /// DELETE: Hapus laporan (admin)
  Future<void> deleteReport(String reportId) async {
    await _db.from('reports').delete().eq('id', reportId);
  }

  // ─────────────────────────────────────────
  // NOTIFICATIONS
  // ─────────────────────────────────────────

  /// CREATE: Kirim notifikasi
  Future<void> createNotification({
    required String recipientId,
    String? senderId,
    required String type,
    required String message,
    String? submissionId,
  }) async {
    await _db.from('notifications').insert({
      'recipient_id': recipientId,
      if (senderId != null) 'sender_id': senderId,
      'type': type,
      'message': message,
      if (submissionId != null) 'submission_id': submissionId,
      'is_read': false,
    });
  }

  /// READ: Ambil notifikasi user
  Future<List<Map<String, dynamic>>> getNotifications(String uid) async {
    final res = await _db
        .from('notifications')
        .select('*, sender:sender_id(username, photo_url)')
        .eq('recipient_id', uid)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(res as List);
  }

  /// UPDATE: Tandai notifikasi sebagai sudah dibaca
  Future<void> markNotificationRead(String notifId) async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notifId);
  }

  /// UPDATE: Tandai semua notifikasi user sebagai sudah dibaca
  Future<void> markAllNotificationsRead(String uid) async {
    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', uid)
        .eq('is_read', false);
  }

  /// DELETE: Hapus satu notifikasi
  Future<void> deleteNotification(String notifId) async {
    await _db.from('notifications').delete().eq('id', notifId);
  }

  // ─────────────────────────────────────────
  // MAPPERS
  // ─────────────────────────────────────────

  UserModel _userFromRow(Map<String, dynamic> row) {
    return UserModel(
      userId: row['id'] as String? ?? '',
      username: row['username'] as String? ?? '',
      email: row['email'] as String? ?? '',
      photoUrl: row['photo_url'] as String? ?? '',
      bio: row['bio'] as String? ?? '',
      totalXp: row['total_xp'] as int? ?? 0,
      weeklyPoints: row['weekly_points'] as int? ?? 0,
      rank: row['rank'] as String? ?? 'Rookie Snapper',
      dailyVotesGiven: 0,
      dailyReportsRemaining: 3,
      lastVoteResetDate: '',
      createdAt: Timestamp.fromDate(
        DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      ),
    );
  }

  ChallengeModel _challengeFromRow(Map<String, dynamic> row) {
    return ChallengeModel(
      challengeId: row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      date: row['date'] as String? ?? '',
      isActive: true,
    );
  }

  SubmissionModel _submissionFromRow(Map<String, dynamic> row) {
    final user = row['users'] as Map<String, dynamic>?;
    return SubmissionModel(
      submissionId: row['id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      challengeId: row['challenge_id'] as String? ?? '',
      username: user?['username'] as String? ?? '',
      userPhotoUrl: user?['photo_url'] as String? ?? '',
      photoUrl: row['photo_url'] as String? ?? '',
      caption: row['caption'] as String? ?? '',
      voteCount: row['vote_count'] as int? ?? 0,
      reportCount: 0,
      isHidden: false,
      submittedAt: Timestamp.fromDate(
        DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      ),
    );
  }

  CommentModel _commentFromRow(Map<String, dynamic> row) {
    final user = row['users'] as Map<String, dynamic>?;
    return CommentModel(
      commentId: row['id'] as String? ?? '',
      submissionId: row['submission_id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      username: user?['username'] as String? ?? '',
      userPhotoUrl: user?['photo_url'] as String? ?? '',
      body: row['content'] as String? ?? '',
      createdAt: Timestamp.fromDate(
        DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      ),
    );
  }
}
