import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  static const _tabs = ['/home', '/feed', '/leaderboard', '/profile'];

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) {
        _currentIndex = i;
        break;
      }
    }

    return Scaffold(
      backgroundColor: c.background,
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.navBackground,
          border: Border(
            top: BorderSide(color: c.primary.withValues(alpha: 0.15), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          backgroundColor: c.navBackground,
          selectedItemColor: c.primary,
          unselectedItemColor: c.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.article_outlined), activeIcon: Icon(Icons.article_rounded), label: 'Feed'),
            BottomNavigationBarItem(icon: Icon(Icons.leaderboard_outlined), activeIcon: Icon(Icons.leaderboard_rounded), label: 'Ranking'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
