import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapquest/models/challenge_model.dart';
import 'package:snapquest/models/submission_model.dart';
import 'package:snapquest/models/user_model.dart';
import 'package:snapquest/models/vote_model.dart';

void main() {
  // Helper timestamp untuk test
  final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 0, 0));

  // ─── ChallengeModel ───────────────────────────────────────────────────────

  group('ChallengeModel', () {
    final map = {
      'title': 'Golden Hour',
      'description': 'Foto saat golden hour',
      'date': '2024-01-15',
      'is_active': true,
    };

    test('fromMap creates model correctly', () {
      final model = ChallengeModel.fromMap(map, 'challenge_1');
      expect(model.challengeId, 'challenge_1');
      expect(model.title, 'Golden Hour');
      expect(model.description, 'Foto saat golden hour');
      expect(model.date, '2024-01-15');
      expect(model.isActive, true);
    });

    test('fromMap handles missing fields with defaults', () {
      final model = ChallengeModel.fromMap({}, 'challenge_empty');
      expect(model.challengeId, 'challenge_empty');
      expect(model.title, '');
      expect(model.description, '');
      expect(model.date, '');
      expect(model.isActive, false);
    });

    test('toMap returns correct map', () {
      final model = ChallengeModel.fromMap(map, 'challenge_1');
      final result = model.toMap();
      expect(result['challenge_id'], 'challenge_1');
      expect(result['title'], 'Golden Hour');
      expect(result['description'], 'Foto saat golden hour');
      expect(result['date'], '2024-01-15');
      expect(result['is_active'], true);
    });

    test('copyWith updates specified fields', () {
      final model = ChallengeModel.fromMap(map, 'challenge_1');
      final updated = model.copyWith(title: 'New Title', isActive: false);
      expect(updated.title, 'New Title');
      expect(updated.isActive, false);
      // field lain tidak berubah
      expect(updated.description, 'Foto saat golden hour');
      expect(updated.date, '2024-01-15');
    });

    test('copyWith without arguments returns same values', () {
      final model = ChallengeModel.fromMap(map, 'challenge_1');
      final copy = model.copyWith();
      expect(copy.challengeId, model.challengeId);
      expect(copy.title, model.title);
      expect(copy.isActive, model.isActive);
    });
  });

  // ─── UserModel ────────────────────────────────────────────────────────────

  group('UserModel', () {
    final map = {
      'user_id': 'user_123',
      'username': 'snapmaster99',
      'email': 'user@test.com',
      'photo_url': 'color_teal',
      'total_xp': 1500,
      'rank': 'Creative Eye',
      'weekly_points': 120,
      'daily_votes_given': 5,
      'daily_reports_remaining': 2,
      'last_vote_reset_date': '2024-01-15',
      'created_at': testTimestamp,
    };

    test('fromMap creates model correctly', () {
      final model = UserModel.fromMap(map);
      expect(model.userId, 'user_123');
      expect(model.username, 'snapmaster99');
      expect(model.email, 'user@test.com');
      expect(model.totalXp, 1500);
      expect(model.rank, 'Creative Eye');
      expect(model.weeklyPoints, 120);
      expect(model.dailyVotesGiven, 5);
      expect(model.dailyReportsRemaining, 2);
    });

    test('fromMap handles missing fields with defaults', () {
      final model = UserModel.fromMap({});
      expect(model.userId, '');
      expect(model.username, '');
      expect(model.totalXp, 0);
      expect(model.rank, 'Rookie Snapper');
      expect(model.dailyReportsRemaining, 3);
    });

    test('toMap returns correct map', () {
      final model = UserModel.fromMap(map);
      final result = model.toMap();
      expect(result['user_id'], 'user_123');
      expect(result['username'], 'snapmaster99');
      expect(result['total_xp'], 1500);
      expect(result['rank'], 'Creative Eye');
      expect(result['weekly_points'], 120);
    });

    test('copyWith updates specified fields only', () {
      final model = UserModel.fromMap(map);
      final updated = model.copyWith(totalXp: 2000, rank: 'SnapMaster');
      expect(updated.totalXp, 2000);
      expect(updated.rank, 'SnapMaster');
      // field lain tetap
      expect(updated.username, 'snapmaster99');
      expect(updated.weeklyPoints, 120);
    });

    test('copyWith dailyVotesGiven increments correctly', () {
      final model = UserModel.fromMap(map);
      final updated = model.copyWith(dailyVotesGiven: model.dailyVotesGiven + 1);
      expect(updated.dailyVotesGiven, 6);
    });
  });

  // ─── SubmissionModel ──────────────────────────────────────────────────────

  group('SubmissionModel', () {
    final map = {
      'user_id': 'user_123',
      'challenge_id': 'challenge_1',
      'username': 'snapmaster99',
      'user_photo_url': 'color_teal',
      'photo_url': 'https://storage.example.com/photo.jpg',
      'caption': 'Sunset keren banget!',
      'vote_count': 10,
      'report_count': 0,
      'is_hidden': false,
      'submitted_at': testTimestamp,
    };

    test('fromMap creates model correctly', () {
      final model = SubmissionModel.fromMap(map, 'submission_abc');
      expect(model.submissionId, 'submission_abc');
      expect(model.userId, 'user_123');
      expect(model.caption, 'Sunset keren banget!');
      expect(model.voteCount, 10);
      expect(model.reportCount, 0);
      expect(model.isHidden, false);
    });

    test('fromMap handles missing fields with defaults', () {
      final model = SubmissionModel.fromMap({}, 'sub_empty');
      expect(model.submissionId, 'sub_empty');
      expect(model.userId, '');
      expect(model.caption, '');
      expect(model.voteCount, 0);
      expect(model.isHidden, false);
    });

    test('toMap returns correct map', () {
      final model = SubmissionModel.fromMap(map, 'submission_abc');
      final result = model.toMap();
      expect(result['submission_id'], 'submission_abc');
      expect(result['user_id'], 'user_123');
      expect(result['vote_count'], 10);
      expect(result['is_hidden'], false);
    });

    test('copyWith increments voteCount correctly', () {
      final model = SubmissionModel.fromMap(map, 'submission_abc');
      final voted = model.copyWith(voteCount: model.voteCount + 1);
      expect(voted.voteCount, 11);
    });

    test('copyWith hides submission when report threshold met', () {
      final model = SubmissionModel.fromMap(map, 'submission_abc');
      final reported = model.copyWith(reportCount: 3, isHidden: true);
      expect(reported.reportCount, 3);
      expect(reported.isHidden, true);
      // data lain tidak berubah
      expect(reported.caption, 'Sunset keren banget!');
    });

    test('copyWith without arguments preserves all fields', () {
      final model = SubmissionModel.fromMap(map, 'submission_abc');
      final copy = model.copyWith();
      expect(copy.submissionId, model.submissionId);
      expect(copy.voteCount, model.voteCount);
      expect(copy.isHidden, model.isHidden);
    });
  });

  // ─── VoteModel ────────────────────────────────────────────────────────────

  group('VoteModel', () {
    final map = {
      'voter_id': 'user_456',
      'submission_id': 'submission_abc',
      'challenge_id': 'challenge_1',
      'voted_at': testTimestamp,
    };

    test('fromMap creates model correctly', () {
      final model = VoteModel.fromMap(map, 'user_456_submission_abc');
      expect(model.voteId, 'user_456_submission_abc');
      expect(model.voterId, 'user_456');
      expect(model.submissionId, 'submission_abc');
      expect(model.challengeId, 'challenge_1');
    });

    test('fromMap handles missing fields with defaults', () {
      final model = VoteModel.fromMap({}, 'vote_empty');
      expect(model.voteId, 'vote_empty');
      expect(model.voterId, '');
      expect(model.submissionId, '');
      expect(model.challengeId, '');
    });

    test('toMap returns correct map', () {
      final model = VoteModel.fromMap(map, 'user_456_submission_abc');
      final result = model.toMap();
      expect(result['vote_id'], 'user_456_submission_abc');
      expect(result['voter_id'], 'user_456');
      expect(result['submission_id'], 'submission_abc');
      expect(result['challenge_id'], 'challenge_1');
    });

    test('voteId follows voterId_submissionId format', () {
      final model = VoteModel.fromMap(map, 'user_456_submission_abc');
      expect(model.voteId, contains('user_456'));
      expect(model.voteId, contains('submission_abc'));
    });
  });
}