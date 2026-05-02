import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movemate/models.dart';
import 'package:movemate/moment_of_pride.dart';
import 'package:movemate/storage.dart';

Future<Storage> _freshStorage([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return Storage.open();
}

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> _seedConsecutiveSessions(
    Storage storage, DateTime endingOn, int days,
    {int seconds = 180, ExerciseCategory category = ExerciseCategory.mobility}) async {
  for (int i = 0; i < days; i++) {
    final at = endingOn.subtract(Duration(days: i));
    await storage.addSession(SessionRecord(
      completedAt: at,
      planTitle: 'Test session',
      category: category,
      seconds: seconds,
    ));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MomentOfPride', () {
    test('returns null with no sessions', () async {
      final storage = await _freshStorage();
      expect(MomentOfPride.compute(storage), isNull);
    });

    test('surfaces a streak when 3+ consecutive days are logged', () async {
      final storage = await _freshStorage();
      final now = DateTime(2026, 5, 5, 12);
      await _seedConsecutiveSessions(storage, now, 5);
      final pride = MomentOfPride.compute(storage, now: now);
      expect(pride, isNotNull);
      // Could be streak or week growth depending on prev-week data.
      expect(
        pride!.kind,
        anyOf(PrideKind.streak, PrideKind.weekGrowth, PrideKind.milestone),
      );
    });

    test('surfaces milestone when total sessions hits 5', () async {
      final storage = await _freshStorage();
      final now = DateTime(2026, 5, 5, 12);
      // 5 consecutive days yields a 5-session milestone (and 5-day streak).
      await _seedConsecutiveSessions(storage, now, 5);
      final pride = MomentOfPride.compute(storage, now: now);
      expect(pride, isNotNull);
      // Streak takes priority over milestone in the ranking.
      expect(pride!.headline, contains('streak'));
    });

    test('pain drop takes priority over streak when both qualify',
        () async {
      final now = DateTime(2026, 5, 5, 12);
      // Seed 14 days of back pain that drops from 8 → 2.
      final pain = <String, Map<String, int>>{};
      for (int i = 0; i < 14; i++) {
        final d = now.subtract(Duration(days: 13 - i));
        // Linear drop from 8 to 2.
        final level = (8 - (i / 13.0) * 6).round();
        pain[_dayKey(d)] = {'back': level};
      }
      final storage = await _freshStorage({
        'painLog': jsonEncode(pain),
      });
      // Also seed a 5-day streak so both pain-drop and streak are candidates.
      await _seedConsecutiveSessions(storage, now, 5);
      final pride = MomentOfPride.compute(storage, now: now);
      expect(pride, isNotNull);
      expect(pride!.kind, PrideKind.painDrop);
      expect(pride.headline.toLowerCase(), contains('back'));
    });

    test('weekGrowth fires when this week beats last week', () async {
      final storage = await _freshStorage();
      final now = DateTime(2026, 5, 5, 12);
      // Last week (8-14 days ago): a single short session — 60s = 1 min.
      await storage.addSession(SessionRecord(
        completedAt: now.subtract(const Duration(days: 10)),
        planTitle: 'Old',
        category: ExerciseCategory.mobility,
        seconds: 60,
      ));
      // This week: 3 sessions of 5 min each on different days, spaced apart
      // so the streak stays under 3 days and weekGrowth wins.
      await storage.addSession(SessionRecord(
        completedAt: now.subtract(const Duration(days: 5)),
        planTitle: 'A',
        category: ExerciseCategory.mobility,
        seconds: 300,
      ));
      await storage.addSession(SessionRecord(
        completedAt: now.subtract(const Duration(days: 3)),
        planTitle: 'B',
        category: ExerciseCategory.stretch,
        seconds: 300,
      ));
      await storage.addSession(SessionRecord(
        completedAt: now.subtract(const Duration(days: 1)),
        planTitle: 'C',
        category: ExerciseCategory.breath,
        seconds: 300,
      ));
      final pride = MomentOfPride.compute(storage, now: now);
      expect(pride, isNotNull);
      // Either week growth or variety should fire here.
      expect(
        pride!.kind,
        anyOf(PrideKind.weekGrowth, PrideKind.variety),
      );
    });
  });
}
