import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

/// Streams Firebase Auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Streams notifications for the current user
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getNotificationsStream(uid);
});

/// Streams the full UserModel for the current user
final userModelProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).getUserStream(uid);
});
