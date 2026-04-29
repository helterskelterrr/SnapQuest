import 'package:flutter_test/flutter_test.dart';
import 'package:snapquest/core/utils/date_helper.dart';

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  group('DateHelper', () {
    group('rankFromXp', () {
      test('returns Rookie Snapper for 0 XP', () {
        expect(DateHelper.rankFromXp(0), 'Rookie Snapper');
      });

      test('returns Rookie Snapper for 499 XP', () {
        expect(DateHelper.rankFromXp(499), 'Rookie Snapper');
      });

      test('returns Rising Shooter for 500 XP', () {
        expect(DateHelper.rankFromXp(500), 'Rising Shooter');
      });

      test('returns Rising Shooter for 1499 XP', () {
        expect(DateHelper.rankFromXp(1499), 'Rising Shooter');
      });

      test('returns Creative Eye for 1500 XP', () {
        expect(DateHelper.rankFromXp(1500), 'Creative Eye');
      });

      test('returns Creative Eye for 2999 XP', () {
        expect(DateHelper.rankFromXp(2999), 'Creative Eye');
      });

      test('returns SnapMaster for 3000 XP', () {
        expect(DateHelper.rankFromXp(3000), 'SnapMaster');
      });

      test('returns SnapMaster for XP above 3000', () {
        expect(DateHelper.rankFromXp(9999), 'SnapMaster');
      });
    });

    group('nextRankXp', () {
      test('returns 500 when XP is 0', () {
        expect(DateHelper.nextRankXp(0), 500);
      });

      test('returns 500 when XP is 499', () {
        expect(DateHelper.nextRankXp(499), 500);
      });

      test('returns 1500 when XP is 500', () {
        expect(DateHelper.nextRankXp(500), 1500);
      });

      test('returns 1500 when XP is 1499', () {
        expect(DateHelper.nextRankXp(1499), 1500);
      });

      test('returns 3000 when XP is 1500', () {
        expect(DateHelper.nextRankXp(1500), 3000);
      });

      test('returns 3000 when already at max rank', () {
        expect(DateHelper.nextRankXp(3000), 3000);
      });

      test('returns 3000 when XP exceeds max rank', () {
        expect(DateHelper.nextRankXp(5000), 3000);
      });
    });

    group('rankEmoji', () {
      test('returns crown for SnapMaster', () {
        expect(DateHelper.rankEmoji('SnapMaster'), '👑');
      });

      test('returns palette for Creative Eye', () {
        expect(DateHelper.rankEmoji('Creative Eye'), '🎨');
      });

      test('returns star for Rising Shooter', () {
        expect(DateHelper.rankEmoji('Rising Shooter'), '🌟');
      });

      test('returns camera for Rookie Snapper', () {
        expect(DateHelper.rankEmoji('Rookie Snapper'), '📷');
      });

      test('returns camera for unknown rank', () {
        expect(DateHelper.rankEmoji('Unknown'), '📷');
      });
    });

    group('formatCountdown', () {
      test('formats duration correctly for 2 hours 30 minutes', () {
        expect(DateHelper.formatCountdown(const Duration(hours: 2, minutes: 30)), '2j 30m');
      });

      test('formats duration correctly for 0 hours 5 minutes', () {
        expect(DateHelper.formatCountdown(const Duration(minutes: 5)), '0j 5m');
      });

      test('formats duration correctly for 23 hours 59 minutes', () {
        expect(DateHelper.formatCountdown(const Duration(hours: 23, minutes: 59)), '23j 59m');
      });

      test('formats duration correctly for exactly 1 hour', () {
        expect(DateHelper.formatCountdown(const Duration(hours: 1)), '1j 0m');
      });

      test('formats duration correctly for 0 hours 0 minutes', () {
        expect(DateHelper.formatCountdown(Duration.zero), '0j 0m');
      });
    });

    group('timeAgo', () {
      test('returns Baru saja for less than 1 minute ago', () {
        final now = DateTime.now().subtract(const Duration(seconds: 30));
        expect(DateHelper.timeAgo(now), 'Baru saja');
      });

      test('returns minutes for less than 1 hour ago', () {
        final now = DateTime.now().subtract(const Duration(minutes: 15));
        expect(DateHelper.timeAgo(now), '15m lalu');
      });

      test('returns hours for less than 24 hours ago', () {
        final now = DateTime.now().subtract(const Duration(hours: 3));
        expect(DateHelper.timeAgo(now), '3j lalu');
      });

      test('returns days for 1 day ago', () {
        final now = DateTime.now().subtract(const Duration(days: 1));
        expect(DateHelper.timeAgo(now), '1h lalu');
      });

      test('returns days for multiple days ago', () {
        final now = DateTime.now().subtract(const Duration(days: 5));
        expect(DateHelper.timeAgo(now), '5h lalu');
      });
    });

    group('todayString / yesterdayString / tomorrowString', () {
      test('todayString returns YYYY-MM-DD format', () {
        final result = DateHelper.todayString();
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(result), isTrue);
      });

      test('yesterdayString is one day before todayString', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        expect(DateHelper.yesterdayString(), _formatDate(yesterday));
      });

      test('tomorrowString is one day after todayString', () {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        expect(DateHelper.tomorrowString(), _formatDate(tomorrow));
      });
    });

    group('isMonday', () {
      test('returns true only on Monday', () {
        final today = DateTime.now();
        expect(DateHelper.isMonday(), today.weekday == DateTime.monday);
      });
    });
  });
}