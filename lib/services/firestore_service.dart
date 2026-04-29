import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/challenge_model.dart';
import '../models/submission_model.dart';
import '../models/vote_model.dart';
import '../models/comment_model.dart';
import '../core/utils/date_helper.dart';
import '../core/utils/notification_service.dart';
import 'supabase_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // USERS
  // ─────────────────────────────────────────

  Future<void> createUser({
    required String uid,
    required String email,
    required String displayName,
    required String username,
    required String avatarColor,
  }) async {
    final user = UserModel(
      userId: uid,
      username: username,
      email: email,
      photoUrl: avatarColor, // Kita simpan kode warna di photoUrl sebagai fallback
      totalXp: 0,
      rank: 'Rookie Snapper',
      weeklyPoints: 0,
      dailyVotesGiven: 0,
      dailyReportsRemaining: 3,
      lastVoteResetDate: '',
      createdAt: Timestamp.now(),
    );
    await _db.collection('users').doc(uid).set(user.toMap());
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<bool> isUsernameTaken(String username, {String? excludeUid}) async {
    final lower = username.toLowerCase();
    final snapshot = await _db.collection('users').where('username_lower', isEqualTo: lower).get();
    if (snapshot.docs.isEmpty) return false;
    if (excludeUid != null && snapshot.docs.length == 1 && snapshot.docs.first.id == excludeUid) return false;
    return true;
  }

  Future<void> updateUserProfile(String uid, String username, String photoUrl, {String? bio}) async {
    // Update user doc first — must not be in the same batch as comments
    // because comments allow update only for admin by default.
    final userRef = _db.collection('users').doc(uid);
    final userUpdate = <String, dynamic>{
      'username': username,
      'username_lower': username.toLowerCase(),
      'photo_url': photoUrl,
    };
    if (bio != null) userUpdate['bio'] = bio;
    await userRef.update(userUpdate);

    // Update submissions (user owns these, allowed)
    final subSnapshot = await _db.collection('submissions').where('user_id', isEqualTo: uid).get();
    if (subSnapshot.docs.isNotEmpty) {
      final subBatch = _db.batch();
      for (final doc in subSnapshot.docs) {
        subBatch.update(doc.reference, {
          'username': username,
          'user_photo_url': photoUrl,
        });
      }
      await subBatch.commit();
    }

    // Update comments (best-effort — rules may restrict this)
    final commentSnapshot = await _db.collection('comments').where('user_id', isEqualTo: uid).get();
    if (commentSnapshot.docs.isNotEmpty) {
      final commentBatch = _db.batch();
      for (final doc in commentSnapshot.docs) {
        commentBatch.update(doc.reference, {
          'username': username,
          'user_photo_url': photoUrl,
        });
      }
      await commentBatch.commit().catchError((_) {});
    }
  }

  Future<void> incrementUserField(
    String uid,
    String field,
    int amount,
  ) async {
    await _db.collection('users').doc(uid).update({
      field: FieldValue.increment(amount),
    });
  }

  /// Check and reset daily vote/report counts if date has changed.
  /// Also resets weekly_points if the current week's Monday hasn't been processed yet.
  Future<void> checkDailyReset(String uid) async {
    final today = DateHelper.todayString();
    final thisMonday = DateHelper.currentWeekMondayString();
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final lastReset = data['last_vote_reset_date'] as String? ?? '';
    final lastWeeklyReset = data['last_weekly_reset_date'] as String? ?? '';

    final updates = <String, dynamic>{};

    if (lastReset != today) {
      updates['daily_votes_given'] = 0;
      updates['daily_reports_remaining'] = 3;
      updates['last_vote_reset_date'] = today;
    }

    // Reset weekly_points once per week (keyed to this week's Monday)
    if (lastWeeklyReset != thisMonday) {
      updates['weekly_points'] = 0;
      updates['last_weekly_reset_date'] = thisMonday;
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  /// Update rank based on total XP
  Future<void> updateRankFromXp(String uid, int totalXp) async {
    final rank = DateHelper.rankFromXp(totalXp);
    await _db.collection('users').doc(uid).update({'rank': rank});
  }

  // ─────────────────────────────────────────
  // CHALLENGES
  // ─────────────────────────────────────────

  /// Live stream of all today's challenges (up to 3)
  Stream<List<ChallengeModel>> getTodayChallengesStream() {
    final today = DateHelper.todayString();
    return _db
        .collection('challenges')
        .where('date', isEqualTo: today)
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChallengeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Legacy: single challenge stream (returns first of today's challenges)
  Stream<ChallengeModel?> getTodayChallengeStream() {
    final today = DateHelper.todayString();
    return _db
        .collection('challenges')
        .where('date', isEqualTo: today)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return ChallengeModel.fromMap(doc.data(), doc.id);
    });
  }

  Future<ChallengeModel?> getYesterdayChallenge() async {
    final yesterday = DateHelper.yesterdayString();
    final snapshot = await _db
        .collection('challenges')
        .where('date', isEqualTo: yesterday)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ChallengeModel.fromMap(doc.data(), doc.id);
  }

  /// Returns how many challenges exist for a given date
  Future<int> getChallengeCountForDate(String date) async {
    final snapshot = await _db
        .collection('challenges')
        .where('date', isEqualTo: date)
        .get();
    return snapshot.docs.length;
  }

  // ─────────────────────────────────────────
  // SUBMISSIONS
  // ─────────────────────────────────────────

  Future<void> createSubmission(SubmissionModel submission) async {
    await _db
        .collection('submissions')
        .doc(submission.submissionId)
        .set(submission.toMap());
  }

  /// Get live feed for all challenges on a given date, sorted by submittedAt desc (Terbaru)
  Stream<List<SubmissionModel>> getSubmissionsByDateStream(String date) {
    return _db
        .collection('submissions')
        .where('challenge_date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
              .where((s) => !s.isHidden)
              .toList();
          docs.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return docs;
        });
  }

  /// Get live feed for all challenges on a given date, sorted by vote_count desc (Terpopuler)
  Stream<List<SubmissionModel>> getSubmissionsByVoteStream(String date) {
    return _db
        .collection('submissions')
        .where('challenge_date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
              .where((s) => !s.isHidden)
              .toList();
          docs.sort((a, b) => b.voteCount.compareTo(a.voteCount));
          return docs;
        });
  }

  /// Get live feed for a specific challenge, sorted by vote_count desc
  Stream<List<SubmissionModel>> getSubmissionsByChallengeVoteStream(String challengeId) {
    return _db
        .collection('submissions')
        .where('challenge_id', isEqualTo: challengeId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
              .where((s) => !s.isHidden)
              .toList();
          docs.sort((a, b) => b.voteCount.compareTo(a.voteCount));
          return docs;
        });
  }

  /// Returns how many submissions a user has for a specific challenge (max 3)
  Future<int> getUserSubmissionCountForChallenge(String userId, String challengeId) async {
    final snapshot = await _db
        .collection('submissions')
        .where('user_id', isEqualTo: userId)
        .where('challenge_id', isEqualTo: challengeId)
        .get();
    return snapshot.docs.length;
  }

  /// Get current user's submission for today's challenge
  Future<SubmissionModel?> getUserSubmissionForChallenge(
    String userId,
    String challengeId,
  ) async {
    final snapshot = await _db
        .collection('submissions')
        .where('user_id', isEqualTo: userId)
        .where('challenge_id', isEqualTo: challengeId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return SubmissionModel.fromMap(doc.data(), doc.id);
  }

  Stream<SubmissionModel?> getUserSubmissionForChallengeStream(
    String userId,
    String challengeId,
  ) {
    return _db
        .collection('submissions')
        .where('user_id', isEqualTo: userId)
        .where('challenge_id', isEqualTo: challengeId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return SubmissionModel.fromMap(doc.data(), doc.id);
    });
  }

  /// Get all submissions by a user (for profile grid)
  Stream<List<SubmissionModel>> getUserAllSubmissionsStream(String userId) {
    return _db
        .collection('submissions')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
              .toList();
          docs.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return docs;
        });
  }

  Future<void> updateSubmission(
    String submissionId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('submissions').doc(submissionId).update(data);
  }

  Future<void> incrementVoteCount(String submissionId) async {
    await _db.collection('submissions').doc(submissionId).update({
      'vote_count': FieldValue.increment(1),
    });
  }

  Future<void> incrementReportCount(String submissionId) async {
    await _db.collection('submissions').doc(submissionId).update({
      'report_count': FieldValue.increment(1),
    });
  }

  /// Check hide condition and update is_hidden if needed
  Future<void> checkAndHideSubmission(String submissionId) async {
    final doc = await _db.collection('submissions').doc(submissionId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final reportCount = data['report_count'] as int? ?? 0;
    final voteCount = data['vote_count'] as int? ?? 0;

    if (reportCount >= 3 && voteCount < reportCount) {
      await _db
          .collection('submissions')
          .doc(submissionId)
          .update({'is_hidden': true});
    }
  }

  /// Get yesterday's top submission (most votes)
  Future<SubmissionModel?> getTopSubmissionYesterday() async {
    final yesterday = await getYesterdayChallenge();
    if (yesterday == null) return null;

    final snapshot = await _db
        .collection('submissions')
        .where('challenge_id', isEqualTo: yesterday.challengeId)
        .get();

    final docs = snapshot.docs
        .map((doc) => SubmissionModel.fromMap(doc.data(), doc.id))
        .where((s) => !s.isHidden)
        .toList();
    if (docs.isEmpty) return null;
    docs.sort((a, b) => b.voteCount.compareTo(a.voteCount));
    return docs.first;
  }

  // ─────────────────────────────────────────
  // VOTES
  // ─────────────────────────────────────────

  Future<void> createVote(VoteModel vote) async {
    await _db.collection('votes').doc(vote.voteId).set(vote.toMap());
  }

  Future<bool> hasVoted(String voterId, String submissionId) async {
    final voteId = '${voterId}_$submissionId';
    final doc = await _db.collection('votes').doc(voteId).get();
    return doc.exists;
  }

  /// Returns a live set of submission IDs the user has voted for (in a specific challenge)
  Stream<Set<String>> getUserVotedSubmissionIdsStream(
    String voterId,
    String challengeId,
  ) {
    return _db
        .collection('votes')
        .where('voter_id', isEqualTo: voterId)
        .where('challenge_id', isEqualTo: challengeId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()['submission_id'] as String).toSet());
  }

  /// Returns a live set of ALL submission IDs the user has voted for
  Stream<Set<String>> getAllUserVotedSubmissionIdsStream(String voterId) {
    return _db
        .collection('votes')
        .where('voter_id', isEqualTo: voterId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()['submission_id'] as String).toSet());
  }

  /// Atomically toggles a vote on a submission.
  /// No daily vote limit — 1 vote per submission per user only.
  Future<void> toggleVote({
    required String voterId,
    required String submissionId,
    required String challengeId,
    required String submissionOwnerId,
    required String voterUsername,
    required String challengeTitle,
  }) async {
    final voteId = '${voterId}_$submissionId';
    final voteRef = _db.collection('votes').doc(voteId);
    final submissionRef = _db.collection('submissions').doc(submissionId);
    final ownerRef = _db.collection('users').doc(submissionOwnerId);

    await _db.runTransaction((transaction) async {
      final voteDoc = await transaction.get(voteRef);
      final isVoted = voteDoc.exists;

      final voterRef = _db.collection('users').doc(voterId);

      if (!isVoted) {
        // Add vote
        final newVote = VoteModel(
          voteId: voteId,
          voterId: voterId,
          submissionId: submissionId,
          challengeId: challengeId,
          votedAt: Timestamp.now(),
        );
        transaction.set(voteRef, newVote.toMap());
        transaction.set(submissionRef, {'vote_count': FieldValue.increment(1)}, SetOptions(merge: true));
        transaction.set(ownerRef, {
          'total_xp': FieldValue.increment(2),
          'weekly_points': FieldValue.increment(2),
        }, SetOptions(merge: true));
        // Track how many votes the voter has given today (for Quest #3)
        transaction.set(voterRef, {'daily_votes_given': FieldValue.increment(1)}, SetOptions(merge: true));
      } else {
        // Remove vote
        transaction.delete(voteRef);
        transaction.set(submissionRef, {'vote_count': FieldValue.increment(-1)}, SetOptions(merge: true));
        transaction.set(ownerRef, {
          'total_xp': FieldValue.increment(-2),
          'weekly_points': FieldValue.increment(-2),
        }, SetOptions(merge: true));
      }
    });

    // Update rank for submission owner based on new XP (best effort)
    try {
      final ownerDoc = await _db.collection('users').doc(submissionOwnerId).get();
      if (ownerDoc.exists) {
        final newXp = ownerDoc.data()?['total_xp'] as int? ?? 0;
        await updateRankFromXp(submissionOwnerId, newXp);
      }
    } catch (_) {}

    // Send notification outside of transaction (best effort)
    if (!(await hasVoted(voterId, submissionId))) {
      // It means it was unvoted, no notification
    } else {
      try {
        await sendVoteNotification(
          recipientId: submissionOwnerId,
          voterId: voterId,
          voterUsername: voterUsername,
          submissionId: submissionId,
          challengeTitle: challengeTitle,
        );
      } catch (_) {}
    }
  }

  // ─────────────────────────────────────────
  // REPORTS
  // ─────────────────────────────────────────

  Future<void> createReport(String reporterId, String submissionId) async {
    final reportId = '${reporterId}_$submissionId';
    await _db.collection('reports').doc(reportId).set({
      'report_id': reportId,
      'reporter_id': reporterId,
      'submission_id': submissionId,
      'reported_at': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasReported(String reporterId, String submissionId) async {
    final reportId = '${reporterId}_$submissionId';
    final doc = await _db.collection('reports').doc(reportId).get();
    return doc.exists;
  }

  // ─────────────────────────────────────────
  // LEADERBOARD
  // ─────────────────────────────────────────

  Stream<List<UserModel>> getWeeklyLeaderboardStream({int limit = 20}) {
    return _db
        .collection('users')
        .orderBy('weekly_points', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<UserModel>> getAllTimeLeaderboardStream({int limit = 20}) {
    return _db
        .collection('users')
        .orderBy('total_xp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList());
  }

  // ─────────────────────────────────────────
  // SEED DATA
  // ─────────────────────────────────────────

  /// Buat tantangan baru
  Future<void> createChallenge({
    required String title,
    required String description,
    required String date,
  }) async {
    final docRef = _db.collection('challenges').doc();
    await docRef.set({
      'challenge_id': docRef.id,
      'title': title,
      'description': description,
      'date': date,
      'is_active': true,
    });
  }

  /// Cek apakah sudah ada tantangan untuk tanggal tertentu
  Future<bool> hasChallengeForDate(String date) async {
    final snapshot = await _db
        .collection('challenges')
        .where('date', isEqualTo: date)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Seed tantangan untuk hari ini dan beberapa hari ke depan
  Future<void> seedChallenges() async {
    final today = DateHelper.todayString();
    final yesterday = DateHelper.yesterdayString();
    final tomorrow = DateHelper.tomorrowString();

    final challenges = [
      {
        'title': 'Foto sesuatu berbentuk lingkaran',
        'description':
            'Temukan objek berbentuk lingkaran di sekitarmu. Bisa roda, piring, jam, atau apapun!',
        'date': today,
        'is_active': true,
      },
      {
        'title': 'Foto bayangan yang menarik',
        'description':
            'Cari bayangan unik — bisa bayangan dirimu, pohon, atau benda apapun.',
        'date': yesterday,
        'is_active': false,
      },
      {
        'title': 'Foto dari sudut yang tidak biasa',
        'description':
            'Ambil foto dari bawah ke atas, atau dari sudut ekstrem yang jarang orang coba.',
        'date': tomorrow,
        'is_active': false,
      },
      {
        'title': 'Foto tekstur yang memukau',
        'description':
            'Temukan permukaan bertekstur unik — kayu tua, tembok bata, kain, atau batu. Tampilkan detail teksturnya!',
        'date': DateHelper.futureDateString(2),
        'is_active': false,
      },
      {
        'title': 'Foto refleksi yang kreatif',
        'description':
            'Gunakan air, kaca, logam, atau permukaan mengkilap apapun untuk menciptakan refleksi yang artistik.',
        'date': DateHelper.futureDateString(3),
        'is_active': false,
      },
      {
        'title': 'Foto monokrom kehidupan sehari-hari',
        'description':
            'Abadikan momen sehari-hari tapi edit menjadi hitam-putih. Temukan keindahan dalam kesederhanaan!',
        'date': DateHelper.futureDateString(4),
        'is_active': false,
      },
      {
        'title': 'Foto siluet yang dramatis',
        'description':
            'Manfaatkan cahaya dari belakang subjek untuk menciptakan siluet yang kuat dan dramatis.',
        'date': DateHelper.futureDateString(5),
        'is_active': false,
      },
    ];

    final batch = _db.batch();
    for (final challenge in challenges) {
      // Cek apakah sudah ada untuk tanggal ini
      final existing = await _db
          .collection('challenges')
          .where('date', isEqualTo: challenge['date'])
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) continue;

      final docRef = _db.collection('challenges').doc();
      batch.set(docRef, {
        'challenge_id': docRef.id,
        ...challenge,
      });
    }
    await batch.commit();
  }

  /// Seed dummy users untuk leaderboard
  Future<void> seedDummyUsers() async {
    final dummyUsers = [
      {
        'user_id': 'dummy_1',
        'username': 'RahaFoto',
        'email': 'raha@snapquest.app',
        'photo_url': '#6366F1',
        'total_xp': 2850,
        'rank': 'SnapMaster',
        'weekly_points': 340,
        'daily_votes_given': 0,
        'daily_reports_remaining': 3,
        'last_vote_reset_date': '',
        'created_at': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 90))),
      },
      {
        'user_id': 'dummy_2',
        'username': 'LensaBiru',
        'email': 'lensa@snapquest.app',
        'photo_url': '#EC4899',
        'total_xp': 1620,
        'rank': 'Creative Eye',
        'weekly_points': 210,
        'daily_votes_given': 0,
        'daily_reports_remaining': 3,
        'last_vote_reset_date': '',
        'created_at': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 60))),
      },
      {
        'user_id': 'dummy_3',
        'username': 'JepretPro',
        'email': 'jepret@snapquest.app',
        'photo_url': '#22C55E',
        'total_xp': 980,
        'rank': 'Rising Shooter',
        'weekly_points': 150,
        'daily_votes_given': 0,
        'daily_reports_remaining': 3,
        'last_vote_reset_date': '',
        'created_at': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 45))),
      },
      {
        'user_id': 'dummy_4',
        'username': 'FotoKita',
        'email': 'fotokita@snapquest.app',
        'photo_url': '#F59E0B',
        'total_xp': 560,
        'rank': 'Rising Shooter',
        'weekly_points': 90,
        'daily_votes_given': 0,
        'daily_reports_remaining': 3,
        'last_vote_reset_date': '',
        'created_at': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 30))),
      },
      {
        'user_id': 'dummy_5',
        'username': 'SnapHarian',
        'email': 'snap@snapquest.app',
        'photo_url': '#06B6D4',
        'total_xp': 240,
        'rank': 'Rookie Snapper',
        'weekly_points': 40,
        'daily_votes_given': 0,
        'daily_reports_remaining': 3,
        'last_vote_reset_date': '',
        'created_at': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 15))),
      },
    ];

    final batch = _db.batch();
    for (final user in dummyUsers) {
      final docRef = _db.collection('users').doc(user['user_id'] as String);
      final existing = await docRef.get();
      if (!existing.exists) {
        batch.set(docRef, user);
      }
    }
    await batch.commit();
  }

  /// Seed dummy submissions untuk challenge kemarin (agar Photo of the Day muncul)
  Future<void> seedDummySubmissions() async {
    final yesterday = await getYesterdayChallenge();
    if (yesterday == null) return;

    final dummySubmissions = [
      {
        'submission_id': 'dummy_sub_1',
        'challenge_id': yesterday.challengeId,
        'user_id': 'dummy_1',
        'username': 'RahaFoto',
        'user_photo_url': '#6366F1',
        'photo_url':
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
        'vote_count': 42,
        'report_count': 0,
        'is_hidden': false,
        'submitted_at': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'submission_id': 'dummy_sub_2',
        'challenge_id': yesterday.challengeId,
        'user_id': 'dummy_2',
        'username': 'LensaBiru',
        'user_photo_url': '#EC4899',
        'photo_url':
            'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=800',
        'vote_count': 31,
        'report_count': 0,
        'is_hidden': false,
        'submitted_at': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'submission_id': 'dummy_sub_3',
        'challenge_id': yesterday.challengeId,
        'user_id': 'dummy_3',
        'username': 'JepretPro',
        'user_photo_url': '#22C55E',
        'photo_url':
            'https://images.unsplash.com/photo-1471107340929-a87cd0f5b5f3?w=800',
        'vote_count': 19,
        'report_count': 0,
        'is_hidden': false,
        'submitted_at': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      },
    ];

    final batch = _db.batch();
    for (final sub in dummySubmissions) {
      final docRef =
          _db.collection('submissions').doc(sub['submission_id'] as String);
      final existing = await docRef.get();
      if (!existing.exists) {
        batch.set(docRef, sub);
      }
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────
  // NOTIFICATIONS
  // ─────────────────────────────────────────

  /// Stream notifikasi untuk user tertentu, sorted by createdAt desc
  Stream<List<Map<String, dynamic>>> getNotificationsStream(String uid) {
    return _db
        .collection('notifications')
        .where('recipient_id', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          docs.sort((a, b) {
            final aTs = a['created_at'];
            final bTs = b['created_at'];
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return (bTs as Timestamp).compareTo(aTs as Timestamp);
          });
          return docs.take(50).toList();
        });
  }

  Future<void> markNotificationRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'read': true});
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final snap = await _db
        .collection('notifications')
        .where('recipient_id', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String notifId) async {
    await _db.collection('notifications').doc(notifId).delete();
  }

  /// Kirim notifikasi vote ke pemilik submission
  Future<void> sendVoteNotification({
    required String recipientId,
    required String voterId,
    required String voterUsername,
    required String submissionId,
    required String challengeTitle,
  }) async {
    if (recipientId == voterId) return; // jangan notif diri sendiri
    final title = '$voterUsername memvote fotomu';
    final body = 'Foto pada challenge "$challengeTitle" mendapat vote baru';
    final docRef = _db.collection('notifications').doc();
    await docRef.set({
      'id': docRef.id,
      'recipient_id': recipientId,
      'type': 'vote',
      'title': title,
      'body': body,
      'sender_username': voterUsername,
      'submission_id': submissionId,
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Sync ke Supabase (relational database)
    await SupabaseService.instance.createNotification(
      recipientId: recipientId,
      senderId: voterId,
      type: 'vote',
      message: body,
      submissionId: submissionId,
    );

    // Send push notification to recipient's device
    await NotificationService().sendPushToUser(
      recipientUid: recipientId,
      title: title,
      body: body,
      submissionId: submissionId,
    );
  }

  // ─────────────────────────────────────────
  // SEED DATA
  // ─────────────────────────────────────────

  // ─────────────────────────────────────────
  // COMMENTS
  // ─────────────────────────────────────────

  /// Stream komentar untuk sebuah submission, diurutkan dari terlama
  Stream<List<CommentModel>> getCommentsStream(String submissionId) {
    return _db
        .collection('comments')
        .where('submission_id', isEqualTo: submissionId)
        .snapshots()
        .map((snap) {
          final comments = snap.docs
              .map((d) {
                final data = Map<String, dynamic>.from(d.data());
                // Server timestamp may be null during pending write — use now() as fallback
                if (data['created_at'] is! Timestamp) {
                  data['created_at'] = Timestamp.now();
                }
                return CommentModel.fromMap(data, d.id);
              })
              .toList();
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
        });
  }

  /// Tambah komentar baru dan increment comments_count di submission secara atomik
  Future<void> addComment(CommentModel comment) async {
    final batch = _db.batch();
    final commentRef = _db.collection('comments').doc();
    batch.set(commentRef, {
      ...comment.toMap(),
      'comment_id': commentRef.id,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('submissions').doc(comment.submissionId), {
      'comments_count': FieldValue.increment(1),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Hapus komentar (hanya pemilik) dan decrement comments_count secara atomik
  Future<void> deleteComment(String commentId, String submissionId) async {
    final batch = _db.batch();
    batch.delete(_db.collection('comments').doc(commentId));
    batch.set(_db.collection('submissions').doc(submissionId), {
      'comments_count': FieldValue.increment(-1),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Kirim notifikasi komentar ke pemilik submission
  Future<void> sendCommentNotification({
    required String recipientId,
    required String commenterId,
    required String commenterUsername,
    required String submissionId,
    required String commentPreview,
  }) async {
    if (recipientId == commenterId) return;
    final title = '$commenterUsername mengomentari fotomu';
    final body = commentPreview.length > 80
        ? '${commentPreview.substring(0, 80)}…'
        : commentPreview;
    final docRef = _db.collection('notifications').doc();
    await docRef.set({
      'id': docRef.id,
      'recipient_id': recipientId,
      'type': 'comment',
      'title': title,
      'body': body,
      'sender_username': commenterUsername,
      'submission_id': submissionId,
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Sync ke Supabase (relational database)
    try {
      await SupabaseService.instance.createNotification(
        recipientId: recipientId,
        senderId: commenterId,
        type: 'comment',
        message: body,
        submissionId: submissionId,
      );
    } catch (e) {
      debugPrint('Gagal sync notifikasi ke Supabase: $e');
    }

    // Send push notification to recipient's device
    await NotificationService().sendPushToUser(
      recipientUid: recipientId,
      title: title,
      body: body,
      submissionId: submissionId,
    );
  }

  // ─────────────────────────────────────────
  // USER SEARCH
  // ─────────────────────────────────────────

  /// Cari user berdasarkan prefix username (Case-insensitive dan fallback)
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    
    // Query 1: username_lower
    final qLower = query.trim().toLowerCase();
    final snap1 = await _db
        .collection('users')
        .where('username_lower', isGreaterThanOrEqualTo: qLower)
        .where('username_lower', isLessThan: '$qLower\uf8ff')
        .limit(20)
        .get();

    // Query 2: username (for older accounts that haven't updated profile)
    final qNormal = query.trim();
    final snap2 = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: qNormal)
        .where('username', isLessThan: '$qNormal\uf8ff')
        .limit(20)
        .get();

    final allDocs = [...snap1.docs, ...snap2.docs];
    final uniqueDocs = <String, DocumentSnapshot>{};
    for (var doc in allDocs) {
      uniqueDocs[doc.id] = doc;
    }
    
    return uniqueDocs.values
        .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  /// Ambil profil publik satu user berdasarkan userId
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Stream semua submission milik user tertentu (untuk profil publik)
  Stream<List<SubmissionModel>> getSubmissionsByUserStream(String userId) {
    return _db
        .collection('submissions')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final docs = snap.docs
              .map((d) => SubmissionModel.fromMap(d.data(), d.id))
              .where((s) => !s.isHidden)
              .toList();
          docs.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return docs;
        });
  }

  /// Jalankan semua seed sekaligus
  Future<void> seedAll() async {
    await seedChallenges();
    await seedDummyUsers();
    await seedDummySubmissions();
  }
}
