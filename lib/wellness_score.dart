import 'models.dart';
import 'storage.dart';

class WellnessScore {
  final int total; // 0..100
  final int streakComponent; // 0..100
  final int varietyComponent; // 0..100
  final int volumeComponent; // 0..100
  final int todayComponent; // 0..100
  final String label;
  final int delta; // vs previous 7-day window

  const WellnessScore({
    required this.total,
    required this.streakComponent,
    required this.varietyComponent,
    required this.volumeComponent,
    required this.todayComponent,
    required this.label,
    required this.delta,
  });

  factory WellnessScore.compute(Storage storage, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final sessions = storage.sessions;
    final goal = storage.dailyGoalMinutes;

    // Streak: 7 days of streak = 100; saturates beyond.
    final streak = storage.currentStreak;
    final streakScore = (streak / 7 * 100).clamp(0, 100).round();

    // Variety: distinct categories used in the last 7 days / total categories.
    final cutoff = clock.subtract(const Duration(days: 7));
    final recent = sessions.where((s) => s.completedAt.isAfter(cutoff));
    final distinctCats = recent.map((s) => s.category).toSet().length;
    final varietyScore =
        (distinctCats / ExerciseCategory.values.length * 100).round();

    // Volume: weekly minutes / (goal * 7).
    final weekSec = recent.fold<int>(0, (sum, s) => sum + s.seconds);
    final weekMin = (weekSec / 60).round();
    final volumeScore = goal == 0
        ? 0
        : (weekMin / (goal * 7) * 100).clamp(0.0, 100.0).round();

    // Today: today minutes / goal.
    final todayMin = storage.todayMinutes;
    final todayScore = goal == 0
        ? 0
        : (todayMin / goal * 100).clamp(0.0, 100.0).round();

    final total = (streakScore * 0.30 +
            varietyScore * 0.25 +
            volumeScore * 0.30 +
            todayScore * 0.15)
        .round();

    final label = _labelFor(total);

    // Compute previous-week delta against the prior 7-day window.
    final prevStart = clock.subtract(const Duration(days: 14));
    final prevEnd = clock.subtract(const Duration(days: 7));
    final prevSessions = sessions.where((s) =>
        s.completedAt.isAfter(prevStart) && s.completedAt.isBefore(prevEnd));
    final prevDistinctCats =
        prevSessions.map((s) => s.category).toSet().length;
    final prevVariety =
        (prevDistinctCats / ExerciseCategory.values.length * 100).round();
    final prevWeekSec =
        prevSessions.fold<int>(0, (sum, s) => sum + s.seconds);
    final prevWeekMin = (prevWeekSec / 60).round();
    final prevVolume = goal == 0
        ? 0
        : (prevWeekMin / (goal * 7) * 100).clamp(0.0, 100.0).round();
    // We don't have streak history snapshots, so approximate prior streak as
    // current streak minus the days that have ended since the start of the
    // prior window; use 0 as a floor.
    final prevStreakApprox = (streak - 7).clamp(0, 999);
    final prevStreakScore = (prevStreakApprox / 7 * 100).clamp(0, 100).round();

    final prevTotal = (prevStreakScore * 0.30 +
            prevVariety * 0.25 +
            prevVolume * 0.30)
        .round();

    return WellnessScore(
      total: total,
      streakComponent: streakScore,
      varietyComponent: varietyScore,
      volumeComponent: volumeScore.toInt(),
      todayComponent: todayScore.toInt(),
      label: label,
      delta: total - prevTotal,
    );
  }

  static String _labelFor(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Strong';
    if (score >= 40) return 'Building';
    if (score >= 20) return 'Getting started';
    return 'Day one';
  }
}
