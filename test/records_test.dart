import 'package:flutter_test/flutter_test.dart';

import 'package:movemate/models.dart';
import 'package:movemate/records.dart';

SessionRecord _s({
  required DateTime at,
  required int seconds,
  ExerciseCategory cat = ExerciseCategory.stretch,
  String title = 'Test',
}) =>
    SessionRecord(
      completedAt: at,
      planTitle: title,
      category: cat,
      seconds: seconds,
    );

void main() {
  group('PersonalRecords', () {
    test('returns empty list when there are no sessions', () {
      expect(PersonalRecords.from(const []), isEmpty);
    });

    test('reports longest streak across non-contiguous days', () {
      // 4 contiguous days, then a gap, then 2 contiguous days.
      final base = DateTime(2026, 5, 1);
      final sessions = <SessionRecord>[
        for (int i = 0; i < 4; i++)
          _s(at: base.add(Duration(days: i)), seconds: 120),
        // gap of 2 days
        _s(at: base.add(const Duration(days: 6)), seconds: 120),
        _s(at: base.add(const Duration(days: 7)), seconds: 120),
      ];
      final records = PersonalRecords.from(sessions);
      final longest =
          records.firstWhere((r) => r.label == 'Longest streak');
      expect(longest.value, '4 days');
    });

    test('best day sums same-day sessions', () {
      final day = DateTime(2026, 5, 2);
      final sessions = [
        _s(at: day.add(const Duration(hours: 8)), seconds: 60),
        _s(at: day.add(const Duration(hours: 12)), seconds: 180),
        _s(at: day.add(const Duration(hours: 18)), seconds: 60),
      ];
      final records = PersonalRecords.from(sessions);
      final best =
          records.firstWhere((r) => r.label == 'Best day');
      // 60 + 180 + 60 = 300 sec = 5 min
      expect(best.value, '5 min');
    });

    test('top focus picks the highest-volume category', () {
      final day = DateTime(2026, 5, 3);
      final sessions = [
        _s(at: day, seconds: 60, cat: ExerciseCategory.stretch),
        _s(
            at: day.add(const Duration(hours: 1)),
            seconds: 300,
            cat: ExerciseCategory.cardio),
        _s(
            at: day.add(const Duration(hours: 2)),
            seconds: 120,
            cat: ExerciseCategory.breath),
      ];
      final records = PersonalRecords.from(sessions);
      final top = records.firstWhere((r) => r.label == 'Top focus');
      expect(top.value, 'Cardio');
    });
  });
}
