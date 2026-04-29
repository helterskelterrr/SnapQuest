import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_strings.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Does NOT create Firestore doc (caller does it).
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  static String mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Kata sandi salah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (min. 6 karakter)';
      case 'network-request-failed':
        return AppStrings.networkError;
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      case 'invalid-credential':
        return 'Email atau kata sandi salah';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
