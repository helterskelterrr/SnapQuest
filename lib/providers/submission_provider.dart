import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/submission_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';
import '../providers/auth_provider.dart';
import '../providers/challenge_provider.dart';

/// Feed sort mode
enum FeedSort { latest, popular }

final feedSortProvider = StateProvider<FeedSort>((ref) => FeedSort.latest);

/// Live feed — all submissions from today's challenges (all 3), latest or popular
final feedProvider = StreamProvider<List<SubmissionModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  final today = ref.watch(todayStringProvider);
  final sort = ref.watch(feedSortProvider);

  final service = ref.watch(firestoreServiceProvider);
  if (sort == FeedSort.popular) {
    return service.getSubmissionsByVoteStream(today);
  }
  return service.getSubmissionsByDateStream(today);
});

/// Live feed for a specific challenge (always popular sort for related photos)
final challengeFeedProvider = StreamProvider.family<List<SubmissionModel>, String>((ref, challengeId) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getSubmissionsByChallengeVoteStream(challengeId);
});

/// Live set of ALL submission IDs the current user has voted for
final userVotedIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value({});
  return ref
      .watch(firestoreServiceProvider)
      .getAllUserVotedSubmissionIdsStream(uid);
});

/// Weekly leaderboard, live — only queries when user is authenticated
final weeklyLeaderboardProvider = StreamProvider<List<UserModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getWeeklyLeaderboardStream();
});

/// All-time leaderboard, live — only queries when user is authenticated
final allTimeLeaderboardProvider = StreamProvider<List<UserModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getAllTimeLeaderboardStream();
});

/// All submissions by the current user (for profile grid)
final userSubmissionsProvider = StreamProvider<List<SubmissionModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getUserAllSubmissionsStream(uid);
});

/// Live comments for a given submission
final commentsProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, submissionId) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getCommentsStream(submissionId);
});

/// Live submissions for any user (used on public profiles from search)
final userPublicSubmissionsProvider =
    StreamProvider.family<List<SubmissionModel>, String>((ref, userId) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref
      .watch(firestoreServiceProvider)
      .getSubmissionsByUserStream(userId);
});