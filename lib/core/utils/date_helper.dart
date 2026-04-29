import 'package:intl/intl.dart';

class DateHelper {
  DateHelper._();

  static String todayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String yesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return DateFormat('yyyy-MM-dd').format(yesterday);
  }

  static String tomorrowString() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateFormat('yyyy-MM-dd').format(tomorrow);
  }

  static String futureDateString(int daysAhead) {
    final date = DateTime.now().add(Duration(days: daysAhead));
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static Duration countdownToMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
    return midnight.difference(now);
  }

  /// Format duration as "Xj Ym"
  static String formatCountdown(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}j ${minutes}m';
  }

  /// Returns whether current time is within first 2 hours of the day (00:00–02:00)
  static bool isWithinFirstTwoHours() {
    final now = DateTime.now();
    return now.hour < 2;
  }

  /// Returns whether today is Monday
  static bool isMonday() {
    return DateTime.now().weekday == DateTime.monday;
  }

  /// Returns the date string of the most recent Monday (including today if Monday)
  static String currentWeekMondayString() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  /// Converts a DateTime to "Xj lalu", "Xm lalu", "Xd lalu" format
  static String timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
  }

  /// Compute XP rank string from total XP
  static String rankFromXp(int xp) {
    if (xp >= 3000) return 'SnapMaster';
    if (xp >= 1500) return 'Creative Eye';
    if (xp >= 500) return 'Rising Shooter';
    return 'Rookie Snapper';
  }

  /// XP needed for next rank
  static int nextRankXp(int currentXp) {
    if (currentXp < 500) return 500;
    if (currentXp < 1500) return 1500;
    if (currentXp < 3000) return 3000;
    return 3000; // Already max rank
  }

  static String rankEmoji(String rank) {
    switch (rank) {
      case 'SnapMaster':
        return '👑';
      case 'Creative Eye':
        return '🎨';
      case 'Rising Shooter':
        return '🌟';
      default:
        return '📷';
    }
  }
}
