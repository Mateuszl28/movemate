import 'body_coverage.dart';
import 'exercise_library.dart';
import 'models.dart';
import 'storage.dart';

class AdaptiveDay {
  final DateTime date;
  final String theme;
  final String reason;
  final WorkoutPlan plan;
  const AdaptiveDay({
    required this.date,
    required this.theme,
    required this.reason,
    required this.plan,
  });
}

class AdaptivePlan {
  final List<AdaptiveDay> days;
  const AdaptivePlan(this.days);

  /// Build a 7-day plan starting today. Each day's primary category is chosen
  /// from a balanced rotation, but biased by signals:
  ///  - Hot pain areas → mobility / stretch sessions targeting them
  ///  - Body-coverage gaps from the last 7 days → fill those gaps first
  ///  - Low recent sleep → favour breath / stretch over cardio
  ///  - High latest energy → cardio gets one extra slot midweek
  ///  - Activity profile shapes default cadence
  static AdaptivePlan build(Storage storage, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final sessions = storage.sessions;
    final coverage = BodyCoverage.lastWeek(sessions, now);
    final hotPains = storage.hotPainAreas();
    final sleep = storage.latestSleep;
    final energy = storage.latestEnergy;
    final profile = storage.profile;

    // Base rotation per profile.
    final baseRotation = _baseRotation(profile);

    // Light tilt for sleep/energy.
    final tiltLow = sleep != null && sleep.hours < 6;
    final tiltHigh = energy != null && energy >= 4;

    final days = <AdaptiveDay>[];
    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      var category = baseRotation[i % baseRotation.length];

      // Sleep bias: swap any cardio in the first 2 days for breath.
      if (tiltLow && i < 2 && category == ExerciseCategory.cardio) {
        category = ExerciseCategory.breath;
      }
      // Energy bias: midweek burst.
      if (tiltHigh && i == 3) category = ExerciseCategory.cardio;

      // Pain bias: if user has hot pain areas, force one day to be a
      // targeted mobility session built from those areas.
      final useTargetedDay =
          hotPains.isNotEmpty && (i == 0 || (i == 4 && hotPains.length > 1));
      WorkoutPlan plan;
      String theme;
      String reason;
      if (useTargetedDay) {
        plan = _planForPainAreas(hotPains);
        theme = 'Pain relief';
        reason =
            'Targets ${hotPains.take(2).map((a) => a.label.toLowerCase()).join(' + ')}.';
      } else {
        // Otherwise, prefer covering a neglected area when possible.
        final neglected = coverage.neglected;
        if (neglected.isNotEmpty &&
            (i == 1 || (i == 5 && neglected.length > 1))) {
          plan = _planForBodyArea(neglected.first, category);
          theme = 'Cover the gap';
          reason =
              'You haven\'t worked ${neglected.first.label.toLowerCase()} recently.';
        } else {
          plan = ExerciseLibrary.buildQuickPlan(category);
          theme = _themeFor(category);
          reason = _reasonFor(category, profile);
        }
      }
      days.add(AdaptiveDay(
          date: date, theme: theme, reason: reason, plan: plan));
    }
    return AdaptivePlan(days);
  }

  static List<ExerciseCategory> _baseRotation(ActivityProfile profile) {
    switch (profile) {
      case ActivityProfile.sedentary:
        return [
          ExerciseCategory.mobility,
          ExerciseCategory.stretch,
          ExerciseCategory.breath,
          ExerciseCategory.cardio,
          ExerciseCategory.mobility,
          ExerciseCategory.stretch,
          ExerciseCategory.breath,
        ];
      case ActivityProfile.active:
        return [
          ExerciseCategory.cardio,
          ExerciseCategory.mobility,
          ExerciseCategory.stretch,
          ExerciseCategory.cardio,
          ExerciseCategory.breath,
          ExerciseCategory.mobility,
          ExerciseCategory.stretch,
        ];
      case ActivityProfile.recovery:
        return [
          ExerciseCategory.breath,
          ExerciseCategory.stretch,
          ExerciseCategory.mobility,
          ExerciseCategory.breath,
          ExerciseCategory.stretch,
          ExerciseCategory.mobility,
          ExerciseCategory.breath,
        ];
    }
  }

  static String _themeFor(ExerciseCategory c) {
    switch (c) {
      case ExerciseCategory.stretch:
        return 'Stretch flow';
      case ExerciseCategory.mobility:
        return 'Mobility tune-up';
      case ExerciseCategory.breath:
        return 'Breath reset';
      case ExerciseCategory.cardio:
        return 'Cardio burst';
    }
  }

  static String _reasonFor(ExerciseCategory c, ActivityProfile p) {
    switch (c) {
      case ExerciseCategory.stretch:
        return 'Lengthen the chain — neck, hips, hamstrings.';
      case ExerciseCategory.mobility:
        return 'Active range of motion through the joints.';
      case ExerciseCategory.breath:
        return p == ActivityProfile.active
            ? 'Down-shift the nervous system.'
            : 'Calm, focus, reset.';
      case ExerciseCategory.cardio:
        return 'Move blood, lift the heart rate, wake up.';
    }
  }

  /// Build a session that prioritises exercises overlapping the painful
  /// areas. Mirrors the tension-map algorithm but biases towards stretch /
  /// mobility (no cardio when in pain).
  static WorkoutPlan _planForPainAreas(List<BodyArea> areas) {
    final pool = ExerciseLibrary.all.where((e) =>
        e.category == ExerciseCategory.stretch ||
        e.category == ExerciseCategory.mobility ||
        e.category == ExerciseCategory.breath);
    final scored = <_Scored>[];
    for (final ex in pool) {
      int hits = 0;
      for (final a in ex.bodyAreas) {
        if (areas.contains(a)) hits += 1;
      }
      if (hits > 0) scored.add(_Scored(ex, hits));
    }
    scored.sort((a, b) => b.hits.compareTo(a.hits));

    final picked = <Exercise>[];
    int total = 0;
    final used = <String>{};
    for (final s in scored) {
      if (used.contains(s.ex.id)) continue;
      picked.add(s.ex);
      used.add(s.ex.id);
      total += s.ex.seconds;
      if (picked.length >= 5 || total >= 240) break;
    }
    if (picked.isEmpty) {
      // Fallback if no exercises in library cover the area.
      return ExerciseLibrary.buildQuickPlan(ExerciseCategory.stretch);
    }
    return WorkoutPlan(
      title: 'Pain relief flow',
      subtitle: '${(total / 60).ceil()} min — targeted release',
      primaryCategory: picked.first.category,
      exercises: picked,
    );
  }

  static WorkoutPlan _planForBodyArea(
      BodyArea area, ExerciseCategory preferred) {
    final pool = ExerciseLibrary.all
        .where((e) => e.bodyAreas.contains(area))
        .toList();
    if (pool.isEmpty) return ExerciseLibrary.buildQuickPlan(preferred);
    // Prefer exercises also matching the day's category.
    pool.sort((a, b) {
      final aMatch = a.category == preferred ? 1 : 0;
      final bMatch = b.category == preferred ? 1 : 0;
      return bMatch.compareTo(aMatch);
    });
    final picked = <Exercise>[];
    int total = 0;
    for (final ex in pool) {
      picked.add(ex);
      total += ex.seconds;
      if (picked.length >= 4 || total >= 200) break;
    }
    return WorkoutPlan(
      title: '${area.label} focus',
      subtitle: '${(total / 60).ceil()} min — close the gap',
      primaryCategory: picked.first.category,
      exercises: picked,
    );
  }
}

class _Scored {
  final Exercise ex;
  final int hits;
  const _Scored(this.ex, this.hits);
}
