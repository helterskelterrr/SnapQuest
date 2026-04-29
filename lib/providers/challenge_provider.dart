import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/challenge_model.dart';
import '../models/submission_model.dart';
import '../providers/auth_provider.dart';
import '../core/utils/date_helper.dart';

/// All of today's challenges (up to 3), live stream
final todayChallengesProvider = StreamProvider<List<ChallengeModel>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getTodayChallengesStream();
});

/// Today's first challenge (legacy compat — used by home card, camera default)
final todayChallengeProvider = StreamProvider<ChallengeModel?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).getTodayChallengeStream();
});

/// Yesterday's challenge, one-time fetch
final yesterdayChallengeProvider = FutureProvider<ChallengeModel?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Future.value(null);
  return ref.watch(firestoreServiceProvider).getYesterdayChallenge();
});

/// Current user's submission for today's first challenge, live stream
final userTodaySubmissionProvider = StreamProvider<SubmissionModel?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  final challenge = ref.watch(todayChallengeProvider).value;
  if (uid == null || challenge == null) return Stream.value(null);
  return ref
      .watch(firestoreServiceProvider)
      .getUserSubmissionForChallengeStream(uid, challenge.challengeId);
});

/// Yesterday's top submission (Photo of the Day)
final photoOfDayProvider = FutureProvider<SubmissionModel?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Future.value(null);
  return ref.watch(firestoreServiceProvider).getTopSubmissionYesterday();
});

/// Today's date string (for feed filtering)
final todayStringProvider = Provider<String>((ref) => DateHelper.todayString());