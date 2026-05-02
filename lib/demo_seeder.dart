import 'dart:convert';
import 'dart:math';

import 'models.dart';

/// Builds a realistic ~30-day data snapshot that exercises every feature on
/// the dashboard: streaks, freezes, mood deltas, pain trending down, sleep
/// log, energy check-ins, hydration, eye breaks, mindful moments, posture.
///
/// Returns a JSON string in the same shape as [Storage.exportAll], so it can
/// be fed straight into [Storage.replaceWithImport].
class DemoSeeder {
  /// Generate a deterministic-but-varied dataset anchored to [now].
  static String generate({DateTime? now, int seed = 7}) {
    final clock = now ?? DateTime.now();
    final rng = Random(seed);
    final data = <String, dynamic>{};

    // --- Profile + settings ----------------------------------------------
    data['onboarded'] = true;
    data['profile'] = ActivityProfile.sedentary.index;
    data['reminderIntervalHours'] = 2;
    data['dailyGoalMinutes'] = 10;
    data['themeMode'] = 0;
    data['coachPersonality'] = 0;
    data['hydrationGoal'] = 8;
    data['quietHoursStart'] = 22;
    data['quietHoursEnd'] = 8;
    data['freezesAvailable'] = 1;
    data['lastFreezeMilestone'] = 2;

    // --- Sessions: ~25 across last 30 days, two skipped days for realism --
    final sessions = <Map<String, dynamic>>[];
    final categoriesPool = ExerciseCategory.values;
    final planTitles = const [
      'Desk reset',
      'Energy boost',
      'Wind-down',
      'Quick mobility session',
      'Quick stretch session',
      'Breathing · Box · 4·4·4·4',
      'Walk break · 2 min',
      'Quick cardio session',
    ];

    final skipDays = <int>{4, 17}; // gaps for a realistic streak (not perfect)
    for (int dayOffset = 29; dayOffset >= 0; dayOffset--) {
      if (skipDays.contains(dayOffset)) continue;
      // 1–2 sessions per active day.
      final count = rng.nextDouble() < 0.35 ? 2 : 1;
      for (int i = 0; i < count; i++) {
        final hour = [8, 12, 17, 20][rng.nextInt(4)];
        final minute = rng.nextInt(50);
        final at = DateTime(
          clock.year,
          clock.month,
          clock.day - dayOffset,
          hour,
          minute,
        );
        final cat = categoriesPool[rng.nextInt(categoriesPool.length)];
        final seconds = 90 + rng.nextInt(220); // 1m30s..5m
        final title = planTitles[rng.nextInt(planTitles.length)];
        // Mood: about 60% of sessions have a delta.
        final hasMood = rng.nextDouble() < 0.6;
        sessions.add({
          't': at.toIso8601String(),
          'p': title,
          'c': cat.index,
          's': seconds,
          if (hasMood) 'mb': 2 + rng.nextInt(3),
          if (hasMood) 'ma': 3 + rng.nextInt(3),
        });
      }
    }
    sessions.sort((a, b) =>
        (b['t'] as String).compareTo(a['t'] as String));
    data['sessions'] =
        sessions.map((s) => jsonEncode(s)).toList(growable: false);

    // --- Pain log: lower back trends from 7 → 2 over 14 days (the story) -
    final painLog = <String, Map<String, int>>{};
    for (int i = 13; i >= 0; i--) {
      final date = DateTime(clock.year, clock.month, clock.day - i);
      final key = _dayKey(date);
      // Linear improvement with a tiny jitter.
      final baseBack = 7 - ((13 - i) * (5 / 13));
      final back = (baseBack + rng.nextDouble() - 0.5).clamp(1.0, 9.0).round();
      final today = <String, int>{
        BodyArea.back.name: back,
      };
      // Neck flares up around days 8..5, then resolves.
      if (i >= 5 && i <= 8) {
        today[BodyArea.neck.name] = 4 + rng.nextInt(3);
      }
      // Wrists nag once or twice.
      if (i == 2 || i == 6) {
        today[BodyArea.wrists.name] = 3 + rng.nextInt(2);
      }
      painLog[key] = today;
    }
    data['painLog'] = jsonEncode(painLog);

    // --- Sleep: 8 entries with mid-range values --------------------------
    final sleepLog = <String, Map<String, num>>{};
    for (int i = 8; i >= 0; i--) {
      if (i == 3) continue; // a missed night for realism
      final date = DateTime(clock.year, clock.month, clock.day - i);
      final key = _dayKey(date);
      final hours = 6.0 + rng.nextDouble() * 2.5; // 6.0..8.5
      final quality = 2 + rng.nextInt(4); // 2..5
      sleepLog[key] = {'h': double.parse(hours.toStringAsFixed(1)), 'q': quality};
    }
    data['sleepLog'] = jsonEncode(sleepLog);

    // --- Energy: last 6 days -------------------------------------------
    final energyLog = <String, List<int>>{};
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(clock.year, clock.month, clock.day - i);
      final key = _dayKey(date);
      energyLog[key] = [2 + rng.nextInt(4)];
    }
    data['energyLog'] = jsonEncode(energyLog);

    // --- Hydration: last 6 days, hitting the goal half the time ---------
    final hydrationLog = <String, int>{};
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(clock.year, clock.month, clock.day - i);
      final key = _dayKey(date);
      hydrationLog[key] = 5 + rng.nextInt(5);
    }
    data['hydrationLog'] = jsonEncode(hydrationLog);

    // --- Eye breaks: 4 today, 2-3 most other days for a streak feel ----
    final eyeBreaksLog = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(clock.year, clock.month, clock.day - i);
      final key = _dayKey(date);
      eyeBreaksLog[key] = i == 0 ? 4 : 1 + rng.nextInt(3);
    }
    data['eyeBreaksLog'] = jsonEncode(eyeBreaksLog);

    // --- Mindful moments: a few entries ---------------------------------
    final mindfulLog = <String, int>{};
    for (final i in const [0, 1, 3, 5]) {
      final date = DateTime(clock.year, clock.month, clock.day - i);
      mindfulLog[_dayKey(date)] = 1 + rng.nextInt(2);
    }
    data['mindfulLog'] = jsonEncode(mindfulLog);

    // --- Posture: two checks, latest at 84% -----------------------------
    final postureLog = <String, List<int>>{
      _dayKey(clock.subtract(const Duration(days: 5))): [60],
      _dayKey(clock): [84],
    };
    data['postureLog'] = jsonEncode(postureLog);

    return jsonEncode({
      '__movemate__': 1,
      '__exportedAt__': clock.toIso8601String(),
      '__demo__': true,
      'data': data,
    });
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
