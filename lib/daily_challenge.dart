import 'models.dart';

enum ChallengeKind {
  categoryMinutes,
  totalSessions,
  earlySession,
  hitDailyGoal,
  variety,
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final ChallengeKind kind;

  /// For categoryMinutes — required minutes in the matching category.
  final int? minutes;
  final ExerciseCategory? category;

  /// For totalSessions / variety — required count.
  final int? count;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.kind,
    this.minutes,
    this.category,
    this.count,
  });

  /// Returns 0..1 progress for the given list of *today's* sessions.
  double progressFor(List<SessionRecord> todaySessions) {
    switch (kind) {
      case ChallengeKind.categoryMinutes:
        final secs = todaySessions
            .where((s) => s.category == category)
            .fold<int>(0, (sum, s) => sum + s.seconds);
        final mins = secs / 60;
        return (mins / minutes!).clamp(0.0, 1.0);
      case ChallengeKind.totalSessions:
        return (todaySessions.length / count!).clamp(0.0, 1.0);
      case ChallengeKind.earlySession:
        final has = todaySessions.any((s) => s.completedAt.hour < 9);
        return has ? 1.0 : 0.0;
      case ChallengeKind.hitDailyGoal:
        // Caller will pass today's minutes vs goal as count/minutes.
        // We treat this as binary completed when minutes >= count (goal).
        final mins = todaySessions
                .fold<int>(0, (sum, s) => sum + s.seconds) /
            60;
        return (mins / count!).clamp(0.0, 1.0);
      case ChallengeKind.variety:
        final cats = todaySessions.map((s) => s.category).toSet();
        return (cats.length / count!).clamp(0.0, 1.0);
    }
  }

  String progressLabelFor(List<SessionRecord> todaySessions) {
    switch (kind) {
      case ChallengeKind.categoryMinutes:
        final secs = todaySessions
            .where((s) => s.category == category)
            .fold<int>(0, (sum, s) => sum + s.seconds);
        final mins = (secs / 60).round();
        return '$mins / $minutes min';
      case ChallengeKind.totalSessions:
        return '${todaySessions.length} / $count sessions';
      case ChallengeKind.earlySession:
        final has = todaySessions.any((s) => s.completedAt.hour < 9);
        return has ? 'Done' : 'Before 9 AM';
      case ChallengeKind.hitDailyGoal:
        final mins = (todaySessions
                    .fold<int>(0, (sum, s) => sum + s.seconds) /
                60)
            .round();
        return '$mins / $count min';
      case ChallengeKind.variety:
        final cats = todaySessions.map((s) => s.category).toSet();
        return '${cats.length} / $count categories';
    }
  }
}

class DailyChallengeService {
  /// Pool of challenges. The service deterministically picks one per day so
  /// the user sees the same challenge if the app re-opens.
  static const List<DailyChallenge> _pool = [
    DailyChallenge(
      id: 'stretch_3',
      title: 'Stretch 3 minutes',
      description: 'Loosen up with three minutes of stretching today.',
      emoji: '🧘',
      kind: ChallengeKind.categoryMinutes,
      minutes: 3,
      category: ExerciseCategory.stretch,
    ),
    DailyChallenge(
      id: 'cardio_3',
      title: 'Quick cardio burst',
      description: 'Three minutes of cardio anywhere in the day.',
      emoji: '🏃',
      kind: ChallengeKind.categoryMinutes,
      minutes: 3,
      category: ExerciseCategory.cardio,
    ),
    DailyChallenge(
      id: 'breath_2',
      title: 'Breathe deeply',
      description: 'Two minutes of focused breathing today.',
      emoji: '🌬️',
      kind: ChallengeKind.categoryMinutes,
      minutes: 2,
      category: ExerciseCategory.breath,
    ),
    DailyChallenge(
      id: 'mobility_3',
      title: 'Mobility minutes',
      description: 'Three minutes of mobility work.',
      emoji: '🌀',
      kind: ChallengeKind.categoryMinutes,
      minutes: 3,
      category: ExerciseCategory.mobility,
    ),
    DailyChallenge(
      id: 'three_breaks',
      title: 'Three movement breaks',
      description: 'Spread three sessions across the day.',
      emoji: '🔁',
      kind: ChallengeKind.totalSessions,
      count: 3,
    ),
    DailyChallenge(
      id: 'two_categories',
      title: 'Mix it up',
      description: 'Use two different categories today.',
      emoji: '🎨',
      kind: ChallengeKind.variety,
      count: 2,
    ),
    DailyChallenge(
      id: 'three_categories',
      title: 'Triple threat',
      description: 'Use three different categories today.',
      emoji: '🏅',
      kind: ChallengeKind.variety,
      count: 3,
    ),
    DailyChallenge(
      id: 'early_bird',
      title: 'Early bird',
      description: 'Get one session done before 9 AM.',
      emoji: '🌅',
      kind: ChallengeKind.earlySession,
    ),
  ];

  static DailyChallenge forDate(DateTime date, {int dailyGoalMinutes = 10}) {
    // Stable hash over yyyy-mm-dd ensures the same challenge re-shows during
    // the day even if the app restarts.
    final key = '${date.year}-${date.month}-${date.day}';
    int hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    final pool = _pool;
    return pool[hash % pool.length];
  }

  static List<SessionRecord> sessionsForToday(
      List<SessionRecord> all, DateTime now) {
    return all
        .where((s) =>
            s.completedAt.year == now.year &&
            s.completedAt.month == now.month &&
            s.completedAt.day == now.day)
        .toList();
  }
}
