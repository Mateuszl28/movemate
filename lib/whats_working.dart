import 'models.dart';
import 'storage.dart';

class WorkingObservation {
  final String emoji;
  final String text;
  const WorkingObservation({required this.emoji, required this.text});
}

/// Pure "what's working" picker — scans recent activity for positive signals
/// the user might miss. Returns at most [maxCount] observations, ranked by
/// how meaningful they are. Empty list means we don't have enough data.
class WhatsWorking {
  static List<WorkingObservation> compute(
    Storage storage, {
    DateTime? now,
    int maxCount = 3,
  }) {
    final at = now ?? DateTime.now();
    final out = <WorkingObservation>[];

    final sessions = storage.sessions;
    final cutoff = at.subtract(const Duration(days: 7));
    final lastWeek =
        sessions.where((s) => s.completedAt.isAfter(cutoff)).toList();
    if (sessions.isEmpty && storage.painLog.isEmpty) return const [];

    // Active days this week.
    final daysThisWeek = lastWeek
        .map((s) => DateTime(s.completedAt.year, s.completedAt.month,
            s.completedAt.day))
        .toSet()
        .length;
    if (daysThisWeek >= 4) {
      out.add(WorkingObservation(
        emoji: '🔥',
        text: '$daysThisWeek active days this week — strong rhythm.',
      ));
    } else if (daysThisWeek == 3) {
      out.add(const WorkingObservation(
        emoji: '🌱',
        text: '3 active days this week — habit forming.',
      ));
    }

    // Pain trending down for any tracked area in 14 days.
    BodyArea? droppedArea;
    int dropAmount = 0;
    for (final area in BodyArea.values) {
      final series = storage.painSeries(area, days: 14);
      final readings = series.whereType<int>().toList();
      if (readings.length < 4) continue;
      final half = readings.length ~/ 2;
      final firstAvg =
          readings.take(half).reduce((a, b) => a + b) / half;
      final secondAvg =
          readings.skip(half).reduce((a, b) => a + b) /
              (readings.length - half);
      final drop = (firstAvg - secondAvg).round();
      if (drop > dropAmount) {
        dropAmount = drop;
        droppedArea = area;
      }
    }
    if (droppedArea != null && dropAmount >= 2) {
      out.add(WorkingObservation(
        emoji: '🩹',
        text: '${droppedArea.label} pain trending down (−$dropAmount).',
      ));
    }

    // Best mood-delta sessions in last 7 days.
    final moodDeltas =
        lastWeek.map((s) => s.moodDelta).whereType<int>().toList();
    if (moodDeltas.length >= 3) {
      final positive = moodDeltas.where((d) => d > 0).length;
      if (positive >= moodDeltas.length / 2 && positive >= 2) {
        out.add(WorkingObservation(
          emoji: '✨',
          text: '$positive of ${moodDeltas.length} sessions lifted your mood.',
        ));
      }
    }

    // Variety bonus.
    final cats = lastWeek.map((s) => s.category).toSet();
    if (cats.length >= 3) {
      out.add(WorkingObservation(
        emoji: '🌈',
        text: '${cats.length} kinds of movement this week — well-rounded.',
      ));
    }

    // Total minutes vs prev week.
    int minutesIn(DateTime endingAt, int days) {
      final start = endingAt.subtract(Duration(days: days));
      final secs = sessions
          .where((s) =>
              s.completedAt.isAfter(start) &&
              !s.completedAt.isAfter(endingAt))
          .fold<int>(0, (sum, s) => sum + s.seconds);
      return (secs / 60).round();
    }
    final thisWeek = minutesIn(at, 7);
    final prevWeek = minutesIn(at.subtract(const Duration(days: 7)), 7);
    if (thisWeek > 0 && prevWeek > 0 && thisWeek > prevWeek + 5) {
      out.add(WorkingObservation(
        emoji: '📈',
        text: '+${thisWeek - prevWeek} min vs last week.',
      ));
    }

    // Best energy hour bucket if we have ≥ 3 energy entries.
    final energy = storage.energyLog;
    int total = 0;
    energy.forEach((_, v) => total += v.length);
    if (total >= 5) {
      final morning = at.hour < 12;
      final latest = storage.latestEnergy;
      if (latest != null && latest >= 4 && morning) {
        out.add(const WorkingObservation(
          emoji: '☀️',
          text: 'Energy is up this morning — good time to move.',
        ));
      }
    }

    if (out.length > maxCount) return out.sublist(0, maxCount);
    return out;
  }
}
