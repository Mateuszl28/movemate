import 'models.dart';
import 'storage.dart';

/// One impressive thing the user has done — picked from a ranked menu of
/// candidates so Home always has something celebratory to surface.
class MomentOfPride {
  final String emoji;
  final String headline; // e.g. "9-day streak"
  final String subline;  // e.g. "Your longest yet"
  final PrideKind kind;

  const MomentOfPride({
    required this.emoji,
    required this.headline,
    required this.subline,
    required this.kind,
  });

  /// Examines storage and returns the most celebration-worthy stat. Returns
  /// null when there isn't enough data yet — callers can hide the card.
  static MomentOfPride? compute(Storage storage, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final sessions = storage.sessions;
    if (sessions.isEmpty) return null;

    final candidates = <MomentOfPride>[];

    // Streak: only celebrate >= 3 days (anything less is noisy).
    final streak = storage.currentStreak;
    if (streak >= 3) {
      candidates.add(MomentOfPride(
        emoji: '🔥',
        headline:
            '$streak-day streak',
        subline: streak >= 14
            ? 'Two weeks of showing up'
            : streak >= 7
                ? 'A full week of consistency'
                : 'Momentum building',
        kind: PrideKind.streak,
      ));
    }

    // Best week vs. previous week: total minutes comparison.
    final last7 = _minutesInWindow(sessions, at, days: 7);
    final prev7 = _minutesInWindow(
        sessions, at.subtract(const Duration(days: 7)),
        days: 7);
    if (last7 > 0 && last7 > prev7 && prev7 > 0) {
      final delta = last7 - prev7;
      candidates.add(MomentOfPride(
        emoji: '📈',
        headline: '+$delta min this week',
        subline: 'Above last week\'s $prev7 min',
        kind: PrideKind.weekGrowth,
      ));
    } else if (prev7 == 0 && last7 >= 10) {
      candidates.add(MomentOfPride(
        emoji: '🌱',
        headline: '$last7 min this week',
        subline: 'You came back — that\'s the hardest part',
        kind: PrideKind.comeback,
      ));
    }

    // Pain improvement: biggest drop across any tracked area in 14 days.
    BodyArea? bestArea;
    int bestDrop = 0;
    for (final area in BodyArea.values) {
      final series = storage.painSeries(area, days: 14);
      final readings = series.whereType<int>().toList();
      if (readings.length < 4) continue;
      final firstHalf = readings.take(readings.length ~/ 2).toList();
      final secondHalf = readings.skip(readings.length ~/ 2).toList();
      if (firstHalf.isEmpty || secondHalf.isEmpty) continue;
      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
      final drop = (firstAvg - secondAvg).round();
      if (drop > bestDrop) {
        bestDrop = drop;
        bestArea = area;
      }
    }
    if (bestArea != null && bestDrop >= 2) {
      candidates.add(MomentOfPride(
        emoji: '🩹',
        headline: '${bestArea.label} pain −$bestDrop',
        subline: 'Trending down over the last 2 weeks',
        kind: PrideKind.painDrop,
      ));
    }

    // Mood lift: average mood delta over last 7 days that's positive.
    final cutoff = at.subtract(const Duration(days: 7));
    final moodDeltas = sessions
        .where((s) => s.completedAt.isAfter(cutoff))
        .map((s) => s.moodDelta)
        .whereType<int>()
        .toList();
    if (moodDeltas.length >= 3) {
      final sum = moodDeltas.reduce((a, b) => a + b);
      final avg = sum / moodDeltas.length;
      if (avg >= 0.5) {
        candidates.add(MomentOfPride(
          emoji: '✨',
          headline: 'Mood +${avg.toStringAsFixed(1)} on average',
          subline: '${moodDeltas.length} sessions you felt better after',
          kind: PrideKind.moodLift,
        ));
      }
    }

    // Body variety: distinct categories used in the last 7 days.
    final cats = sessions
        .where((s) => s.completedAt.isAfter(cutoff))
        .map((s) => s.category)
        .toSet();
    if (cats.length >= 3) {
      candidates.add(MomentOfPride(
        emoji: '🌈',
        headline: '${cats.length} kinds of movement',
        subline: 'Well-rounded week — keep mixing it up',
        kind: PrideKind.variety,
      ));
    }

    // Total sessions milestone: 5/10/25/50/100.
    final total = sessions.length;
    final milestones = [5, 10, 25, 50, 100, 200, 365];
    for (final m in milestones.reversed) {
      if (total >= m && total < m + 3) {
        candidates.add(MomentOfPride(
          emoji: '🏅',
          headline: '$total sessions logged',
          subline: m == 100
              ? 'Triple digits — incredible commitment'
              : m >= 50
                  ? 'You\'re building something real'
                  : 'The habit is taking root',
          kind: PrideKind.milestone,
        ));
        break;
      }
    }

    if (candidates.isEmpty) return null;

    // Priority: pain drop > streak > week growth > milestone > mood > variety > comeback.
    const order = [
      PrideKind.painDrop,
      PrideKind.streak,
      PrideKind.weekGrowth,
      PrideKind.milestone,
      PrideKind.moodLift,
      PrideKind.variety,
      PrideKind.comeback,
    ];
    candidates.sort((a, b) =>
        order.indexOf(a.kind).compareTo(order.indexOf(b.kind)));
    return candidates.first;
  }

  static int _minutesInWindow(List<SessionRecord> sessions, DateTime end,
      {required int days}) {
    final start = end.subtract(Duration(days: days));
    final secs = sessions
        .where((s) =>
            s.completedAt.isAfter(start) && !s.completedAt.isAfter(end))
        .fold<int>(0, (sum, s) => sum + s.seconds);
    return (secs / 60).round();
  }
}

enum PrideKind {
  painDrop,
  streak,
  weekGrowth,
  milestone,
  moodLift,
  variety,
  comeback,
}
