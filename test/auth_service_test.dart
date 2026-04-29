import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapquest/core/constants/app_strings.dart';
import 'package:snapquest/services/auth_service.dart';

void main() {
  group('AuthService.mapAuthError', () {
    FirebaseAuthException makeException(String code) {
      return FirebaseAuthException(code: code, message: 'Test error');
    }

    const knownCodes = {
      'user-not-found': 'Email tidak terdaftar',
      'wrong-password': 'Kata sandi salah',
      'email-already-in-use': 'Email sudah digunakan',
      'invalid-email': 'Format email tidak valid',
      'weak-password': 'Kata sandi terlalu lemah (min. 6 karakter)',
      'network-request-failed': AppStrings.networkError,
      'too-many-requests': 'Terlalu banyak percobaan. Coba lagi nanti',
      'invalid-credential': 'Email atau kata sandi salah',
    };

    for (final entry in knownCodes.entries) {
      test('maps ${entry.key} correctly', () {
        expect(AuthService.mapAuthError(makeException(entry.key)), entry.value);
      });
    }

    test('returns generic message for unknown error code', () {
      final exception = FirebaseAuthException(
        code: 'unknown-error',
        message: 'Something went wrong',
      );
      final result = AuthService.mapAuthError(exception);
      expect(result, contains('Terjadi kesalahan'));
      expect(result, contains('Something went wrong'));
    });

    test('returns generic message when message is null', () {
      final exception = FirebaseAuthException(
        code: 'some-other-error',
        message: null,
      );
      final result = AuthService.mapAuthError(exception);
      expect(result, contains('Terjadi kesalahan'));
    });
  });
}