import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movemate/models.dart';
import 'package:movemate/storage.dart';
import 'package:movemate/whats_working.dart';

Future<Storage> _freshStorage([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return Storage.open();
}

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> _seedConsecutiveSessions(
    Storage storage, DateTime endingOn, int days,
    {int seconds = 240,
    ExerciseCategory category = ExerciseCategory.mobility}) async {
  for (int i = 0; i < days; i++) {
    final at = endingOn.subtract(Duration(days: i));
    await storage.addSession(SessionRecord(
      completedAt: at,
      planTitle: 'Test',
      category: category,
      seconds: seconds,
    ));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WhatsWorking', () {
    test('returns empty when there is no data at all', () async {
      final storage = await _freshStorage();
      expect(WhatsWorking.compute(storage), isEmpty);
    });

    test('flags the active-day rhythm when 4+ days had a session this week',
        () async {
      final storage = await _freshStorage();
      final now = DateTime(2026, 5, 5, 12);
      await _seedConsecutiveSessions(storage, now, 5);
      final out = WhatsWorking.compute(storage, now: now);
      expect(out, isNotEmpty);
      expect(
        out.any((o) => o.text.contains('active days')),
        isTrue,
      );
    });

    test('surfaces a pain-down observation when readings drop ≥ 2', () async {
      final now = DateTime(2026, 5, 5, 12);
      // Linear drop from 8 → 2 over 14 days, back area.
      final pain = <String, Map<String, int>>{};
      for (int i = 0; i < 14; i++) {
        final d = now.subtract(Duration(days: 13 - i));
        final level = (8 - (i / 13.0) * 6).round();
        pain[_dayKey(d)] = {'back': level};
      }
      final storage = await _freshStorage({
        'painLog': jsonEncode(pain),
      });
      final out = WhatsWorking.compute(storage, now: now);
      expect(
        out.any((o) =>
            o.text.toLowerCase().contains('back') &&
            o.text.contains('trending down')),
        isTrue,
      );
    });

    test('caps observations at maxCount', () async {
      final storage = await _freshStorage();
      final now = DateTime(2026, 5, 5, 12);
      // 5 days of varied sessions to trigger multiple signals.
      final cats = [
        ExerciseCategory.mobility,
        ExerciseCategory.stretch,
        ExerciseCategory.breath,
        ExerciseCategory.cardio,
        ExerciseCategory.mobility,
      ];
      for (int i = 0; i < cats.length; i++) {
        await storage.addSession(SessionRecord(
          completedAt: now.subtract(Duration(days: i)),
          planTitle: 'Test',
          category: cats[i],
          seconds: 600,
          moodBefore: 3,
          moodAfter: 4,
        ));
      }
      final out = WhatsWorking.compute(storage, now: now, maxCount: 2);
      expect(out.length, lessThanOrEqualTo(2));
    });
  });
}
