import 'exercise_library.dart';
import 'models.dart';
import 'storage.dart';

class SmartRecommendation {
  final WorkoutPlan plan;
  final String reason;
  const SmartRecommendation({required this.plan, required this.reason});
}

class Recommender {
  static SmartRecommendation pick(Storage storage, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final sessions = storage.sessions;
    final profile = storage.profile;
    final dailyGoal = storage.dailyGoalMinutes;
    final todayMin = storage.todayMinutes;
    final energy = storage.latestEnergy;

    // 1) If today's daily goal is essentially hit, suggest a calming wind-down.
    if (dailyGoal > 0 && todayMin >= dailyGoal) {
      return SmartRecommendation(
        plan: ExerciseLibrary.featuredPlans[2], // Wind-down
        reason: 'You hit today\'s goal — finish strong with a wind-down.',
      );
    }

    // 1b) Energy-driven nudge — only when the user has actually checked in today.
    if (energy != null && _energyLoggedToday(storage, clock)) {
      if (energy <= 2) {
        return SmartRecommendation(
          plan: ExerciseLibrary.buildQuickPlan(ExerciseCategory.breath),
          reason:
              'You flagged low energy — a breathing reset is the gentlest way back.',
        );
      }
      if (energy >= 4) {
        return SmartRecommendation(
          plan: ExerciseLibrary.buildQuickPlan(ExerciseCategory.cardio),
          reason:
              'High-energy check-in — let\'s spend some of it on a quick cardio burst.',
        );
      }
    }

    final cutoff = clock.subtract(const Duration(days: 7));
    final recent =
        sessions.where((s) => s.completedAt.isAfter(cutoff)).toList();

    // Aggregate per-category seconds for the last 7 days.
    final perCat = <ExerciseCategory, int>{};
    for (final c in ExerciseCategory.values) {
      perCat[c] = 0;
    }
    for (final s in recent) {
      perCat.update(s.category, (v) => v + s.seconds, ifAbsent: () => s.seconds);
    }

    // 2) If a category was completely skipped this week, lead with it.
    final skipped = perCat.entries.where((e) => e.value == 0).map((e) => e.key).toList();
    if (recent.isNotEmpty && skipped.isNotEmpty) {
      // Prefer stretching/mobility for a sedentary user, breathing for recovery.
      ExerciseCategory pick = skipped.first;
      if (skipped.contains(ExerciseCategory.stretch) &&
          profile == ActivityProfile.sedentary) {
        pick = ExerciseCategory.stretch;
      } else if (skipped.contains(ExerciseCategory.breath) &&
          profile == ActivityProfile.recovery) {
        pick = ExerciseCategory.breath;
      } else if (skipped.contains(ExerciseCategory.cardio) &&
          profile == ActivityProfile.active) {
        pick = ExerciseCategory.cardio;
      }
      return SmartRecommendation(
        plan: ExerciseLibrary.buildQuickPlan(pick),
        reason:
            'You haven\'t done any ${pick.label.toLowerCase()} this week — let\'s balance it out.',
      );
    }

    // 3) If last session was within the last hour, suggest something light.
    if (recent.isNotEmpty) {
      final last = recent
          .reduce((a, b) => a.completedAt.isAfter(b.completedAt) ? a : b);
      final since = clock.difference(last.completedAt);
      if (since.inMinutes < 60 && last.category != ExerciseCategory.breath) {
        return SmartRecommendation(
          plan: ExerciseLibrary.buildQuickPlan(ExerciseCategory.breath),
          reason:
              'You moved ${since.inMinutes} min ago — a short breathing reset works well now.',
        );
      }
    }

    // 4) First session ever — nudge into a desk reset.
    if (sessions.isEmpty) {
      return const SmartRecommendation(
        plan: WorkoutPlan(
          title: 'Desk reset',
          subtitle: '3 min — neck, shoulders, breath',
          primaryCategory: ExerciseCategory.stretch,
          exercises: [
            Exercise(
              id: 'neck_rolls',
              name: 'Neck rolls',
              instruction: 'Slow circles in both directions.',
              seconds: 40,
              category: ExerciseCategory.stretch,
              emoji: '🙆',
            ),
            Exercise(
              id: 'shoulder_rolls',
              name: 'Shoulder rolls',
              instruction: 'Big circles backwards.',
              seconds: 40,
              category: ExerciseCategory.stretch,
              emoji: '🤸',
            ),
            Exercise(
              id: 'box_breath',
              name: 'Box breathing',
              instruction: '4 — 4 — 4 — 4.',
              seconds: 60,
              category: ExerciseCategory.breath,
              emoji: '🫁',
            ),
          ],
        ),
        reason: 'Welcome — start with a 3-minute desk reset.',
      );
    }

    // 5) Time-of-day fallback.
    final hour = clock.hour;
    if (hour < 11) {
      return SmartRecommendation(
        plan: ExerciseLibrary.featuredPlans[1], // Energy boost
        reason: 'A morning energy boost will get the day moving.',
      );
    }
    if (hour >= 21) {
      return SmartRecommendation(
        plan: ExerciseLibrary.featuredPlans[2], // Wind-down
        reason: 'Late evening — let\'s wind down with breathing.',
      );
    }

    // 6) Otherwise default to a desk reset midday.
    return SmartRecommendation(
      plan: ExerciseLibrary.featuredPlans[0],
      reason: 'Midday slump? A 3-minute desk reset clears the head.',
    );
  }

  static bool _energyLoggedToday(Storage storage, DateTime clock) {
    final log = storage.energyLog;
    final key =
        '${clock.year.toString().padLeft(4, '0')}-${clock.month.toString().padLeft(2, '0')}-${clock.day.toString().padLeft(2, '0')}';
    final today = log[key];
    return today != null && today.isNotEmpty;
  }
}
