import 'models.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final bool Function(_AchievementStats stats) check;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.check,
  });
}

class _AchievementStats {
  final int sessionCount;
  final int totalMinutes;
  final int currentStreak;
  final Set<ExerciseCategory> categoriesTried;
  final bool hadEarlySession; // before 9:00
  final bool hadLateSession; // after 21:00
  final bool hitDailyGoalToday;

  _AchievementStats({
    required this.sessionCount,
    required this.totalMinutes,
    required this.currentStreak,
    required this.categoriesTried,
    required this.hadEarlySession,
    required this.hadLateSession,
    required this.hitDailyGoalToday,
  });

  factory _AchievementStats.from(
      List<SessionRecord> sessions, int currentStreak, int dailyGoalMinutes) {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month}-${today.day}';
    int totalSec = 0;
    int todaySec = 0;
    final cats = <ExerciseCategory>{};
    bool early = false;
    bool late = false;
    for (final s in sessions) {
      totalSec += s.seconds;
      cats.add(s.category);
      if (s.completedAt.hour < 9) early = true;
      if (s.completedAt.hour >= 21) late = true;
      final key =
          '${s.completedAt.year}-${s.completedAt.month}-${s.completedAt.day}';
      if (key == todayKey) todaySec += s.seconds;
    }
    return _AchievementStats(
      sessionCount: sessions.length,
      totalMinutes: (totalSec / 60).round(),
      currentStreak: currentStreak,
      categoriesTried: cats,
      hadEarlySession: early,
      hadLateSession: late,
      hitDailyGoalToday: (todaySec / 60).round() >= dailyGoalMinutes,
    );
  }
}

class AchievementCatalog {
  static final List<Achievement> all = [
    Achievement(
      id: 'first_steps',
      name: 'First steps',
      description: 'Complete your first session.',
      emoji: '🌱',
      check: (s) => s.sessionCount >= 1,
    ),
    Achievement(
      id: 'on_a_roll',
      name: 'On a roll',
      description: 'Move 3 days in a row.',
      emoji: '🔥',
      check: (s) => s.currentStreak >= 3,
    ),
    Achievement(
      id: 'week_warrior',
      name: 'Week warrior',
      description: 'Reach a 7-day streak.',
      emoji: '⚔️',
      check: (s) => s.currentStreak >= 7,
    ),
    Achievement(
      id: 'ten_sessions',
      name: 'Repeat customer',
      description: 'Complete 10 sessions.',
      emoji: '🔁',
      check: (s) => s.sessionCount >= 10,
    ),
    Achievement(
      id: 'hour_of_power',
      name: 'Hour of power',
      description: 'Accumulate 60 minutes of movement.',
      emoji: '⏱️',
      check: (s) => s.totalMinutes >= 60,
    ),
    Achievement(
      id: 'marathon_mind',
      name: 'Marathon mind',
      description: 'Reach 200 total minutes.',
      emoji: '🏃',
      check: (s) => s.totalMinutes >= 200,
    ),
    Achievement(
      id: 'all_rounder',
      name: 'All-rounder',
      description: 'Try every category at least once.',
      emoji: '🎯',
      check: (s) =>
          s.categoriesTried.length == ExerciseCategory.values.length,
    ),
    Achievement(
      id: 'early_bird',
      name: 'Early bird',
      description: 'Complete a session before 9 AM.',
      emoji: '🌅',
      check: (s) => s.hadEarlySession,
    ),
    Achievement(
      id: 'night_owl',
      name: 'Night owl',
      description: 'Complete a session after 9 PM.',
      emoji: '🌙',
      check: (s) => s.hadLateSession,
    ),
    Achievement(
      id: 'perfect_day',
      name: 'Perfect day',
      description: 'Hit your daily movement goal.',
      emoji: '🏆',
      check: (s) => s.hitDailyGoalToday,
    ),
  ];

  static List<Achievement> earned(List<SessionRecord> sessions, int streak,
      int dailyGoalMinutes) {
    final stats = _AchievementStats.from(sessions, streak, dailyGoalMinutes);
    return all.where((a) => a.check(stats)).toList();
  }
}
