import 'models.dart';

class PersonalRecord {
  final String label;
  final String value;
  final String emoji;
  final String? hint;
  const PersonalRecord({
    required this.label,
    required this.value,
    required this.emoji,
    this.hint,
  });
}

class PersonalRecords {
  /// Compute lifetime records from raw session history. Returns an ordered
  /// list — most "fun" first — that the UI can render as a grid or list.
  static List<PersonalRecord> from(List<SessionRecord> sessions) {
    if (sessions.isEmpty) return const [];

    int totalSec = 0;
    SessionRecord longest = sessions.first;
    final perDaySec = <String, int>{};
    final perCategorySec = <ExerciseCategory, int>{};
    int earliestHour = 24;
    int latestHour = -1;
    DateTime? firstAt;
    final allDays = <String>{};

    for (final s in sessions) {
      totalSec += s.seconds;
      if (s.seconds > longest.seconds) longest = s;
      final key = _dayKey(s.completedAt);
      perDaySec[key] = (perDaySec[key] ?? 0) + s.seconds;
      perCategorySec.update(s.category, (v) => v + s.seconds,
          ifAbsent: () => s.seconds);
      allDays.add(key);
      if (s.completedAt.hour < earliestHour) earliestHour = s.completedAt.hour;
      if (s.completedAt.hour > latestHour) latestHour = s.completedAt.hour;
      if (firstAt == null || s.completedAt.isBefore(firstAt)) {
        firstAt = s.completedAt;
      }
    }

    // Best day
    String? bestDayKey;
    int bestDaySec = 0;
    perDaySec.forEach((k, v) {
      if (v > bestDaySec) {
        bestDaySec = v;
        bestDayKey = k;
      }
    });

    // Longest streak ever (contiguous session days).
    final longestStreak = _longestStreak(allDays);

    // Top category by total seconds.
    ExerciseCategory? topCat;
    int topCatSec = 0;
    perCategorySec.forEach((k, v) {
      if (v > topCatSec) {
        topCatSec = v;
        topCat = k;
      }
    });

    final daysSinceFirst = firstAt == null
        ? 0
        : DateTime.now().difference(firstAt).inDays + 1;

    return [
      PersonalRecord(
        emoji: '🔥',
        label: 'Longest streak',
        value: longestStreak == 0
            ? '—'
            : '$longestStreak ${longestStreak == 1 ? "day" : "days"}',
      ),
      PersonalRecord(
        emoji: '⏱️',
        label: 'Longest session',
        value: _fmtMinSec(longest.seconds),
        hint: longest.planTitle,
      ),
      PersonalRecord(
        emoji: '🌟',
        label: 'Best day',
        value: '${(bestDaySec / 60).round()} min',
        hint: bestDayKey,
      ),
      PersonalRecord(
        emoji: '📊',
        label: 'Total time',
        value: _fmtTotal(totalSec),
      ),
      PersonalRecord(
        emoji: '🎯',
        label: 'Total sessions',
        value: '${sessions.length}',
      ),
      if (topCat != null)
        PersonalRecord(
          emoji: '🏆',
          label: 'Top focus',
          value: topCat!.label,
          hint: '${(topCatSec / 60).round()} min lifetime',
        ),
      PersonalRecord(
        emoji: '📅',
        label: 'On the journey',
        value: '$daysSinceFirst ${daysSinceFirst == 1 ? "day" : "days"}',
      ),
      if (earliestHour < 24 && latestHour >= 0)
        PersonalRecord(
          emoji: '🕒',
          label: 'Active window',
          value:
              '${earliestHour.toString().padLeft(2, '0')}:00 → ${latestHour.toString().padLeft(2, '0')}:00',
        ),
    ];
  }

  static int _longestStreak(Set<String> dayKeys) {
    if (dayKeys.isEmpty) return 0;
    final dates = dayKeys.map(DateTime.parse).toList()..sort();
    int best = 1;
    int run = 1;
    for (int i = 1; i < dates.length; i++) {
      final gap = dates[i].difference(dates[i - 1]).inDays;
      if (gap == 1) {
        run += 1;
        if (run > best) best = run;
      } else if (gap == 0) {
        // Same day — shouldn't happen since dayKeys is a set, but be safe.
        continue;
      } else {
        run = 1;
      }
    }
    return best;
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtMinSec(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }

  static String _fmtTotal(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '$m min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}
