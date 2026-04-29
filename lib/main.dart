import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';

import 'screens/home/home_screen.dart';
import 'screens/camera/camera_screen.dart';
import 'screens/feed/feed_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/all_submissions_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/post/post_detail_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/shell/app_shell.dart';
import 'screens/home/create_challenge_screen.dart';
import 'screens/search/user_search_screen.dart';
import 'screens/profile/public_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase (relational database)
  await Supabase.initialize(
    url: 'https://ghjchrjykfnzpsdcuujt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdoamNocmp5a2ZuenBzZGN1dWp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0MDM3MTUsImV4cCI6MjA5Mjk3OTcxNX0.L_5xDEQOFz7A4XGaaIbr8_thptNJX10HrlbyIOGCuBE',
  );

  // Register FCM background handler before anything else
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize local notifications + FCM
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();
  await notificationService.scheduleDailyNotifications();

  // Save FCM token when user is already logged in (e.g. app restart)
  // Gunakan authStateChanges().first agar tidak null secara sinkron di awal
  final currentUser = await FirebaseAuth.instance.authStateChanges().first;
  if (currentUser != null) {
    await notificationService.saveFcmToken(currentUser.uid);
    
    // Sinkronisasi data user dari Firestore ke Supabase 
    // untuk mencegah error Foreign Key bagi pengguna lama
    try {
      final firestoreDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
          
      if (firestoreDoc.exists) {
        final data = firestoreDoc.data()!;
        await Supabase.instance.client.from('users').upsert({
          'id': currentUser.uid,
          'username': data['username'] ?? '',
          'username_lower': data['username_lower'] ?? (data['username'] ?? '').toLowerCase(),
          'email': data['email'] ?? currentUser.email ?? '',
          'photo_url': data['photo_url'] ?? '',
        });
      }
    } catch (e) {
      debugPrint('Gagal sinkronisasi user ke Supabase: $e');
    }
  }

  runApp(const ProviderScope(child: SnapQuestApp()));
}

// Global key for navigator if needed
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth state stream to trigger router refresh
  final refreshNotifier = _GoRouterRefreshStream(
    ref.watch(authServiceProvider).authStateChanges,
  );
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    debugLogDiagnostics: true, // Untuk membantu debugging di konsol
    redirect: (context, state) {
      // Gunakan FirebaseAuth.instance.currentUser (sync) agar tidak tertunda
      // oleh AsyncLoading dari authStateProvider
      final user = FirebaseAuth.instance.currentUser;
      final isAuth = user != null;
      final location = state.uri.path;

      final publicRoutes = ['/splash', '/login', '/register'];
      final isPublic = publicRoutes.contains(location);

      // Logika Redirect
      if (!isAuth) {
        // Belum login: paksa ke /login kecuali sudah di /login, /register, atau /splash
        if (location == '/splash' || location == '/login' || location == '/register') return null;
        return '/login';
      } else {
        // Sudah login: jangan biarkan di halaman public
        if (isPublic) return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) => PostDetailScreen(
          postId: state.pathParameters['id'] ?? '1',
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/submissions',
        builder: (context, state) => const AllSubmissionsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/challenge/create',
        builder: (context, state) => const CreateChallengeScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const UserSearchScreen(),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) => PublicProfileScreen(
          userId: state.pathParameters['id'] ?? '',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/feed',
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class SnapQuestApp extends ConsumerWidget {
  const SnapQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.amber,
        surface: AppColors.cardSurface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardSurface,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.amber,
        surface: AppColors.cardSurfaceDark,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardSurfaceDark,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      useMaterial3: true,
    );

    return MaterialApp.router(
      title: 'SnapQuest',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
    );
  }
}
