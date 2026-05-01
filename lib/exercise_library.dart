import 'models.dart';

class ExerciseLibrary {
  static const List<Exercise> all = [
    // Stretch
    Exercise(
      id: 'neck_rolls',
      name: 'Neck rolls',
      instruction: 'Slow circles in both directions, let the shoulders drop.',
      seconds: 40,
      category: ExerciseCategory.stretch,
      emoji: '🙆',
    ),
    Exercise(
      id: 'shoulder_rolls',
      name: 'Shoulder rolls',
      instruction: 'Big circles backwards, open the chest.',
      seconds: 30,
      category: ExerciseCategory.stretch,
      emoji: '🤸',
    ),
    Exercise(
      id: 'chest_opener',
      name: 'Chest opener',
      instruction: 'Clasp hands behind your back, gently pull shoulders back.',
      seconds: 45,
      category: ExerciseCategory.stretch,
      emoji: '🧘',
    ),
    Exercise(
      id: 'side_bend',
      name: 'Side bends',
      instruction: 'Standing, one arm overhead — lengthen the side body.',
      seconds: 40,
      category: ExerciseCategory.stretch,
      emoji: '🌿',
    ),
    Exercise(
      id: 'forward_fold',
      name: 'Forward fold',
      instruction: 'Slowly roll the spine down, breathe into your back.',
      seconds: 45,
      category: ExerciseCategory.stretch,
      emoji: '🙇',
    ),
    Exercise(
      id: 'hamstring',
      name: 'Hamstring stretch',
      instruction: 'Heel on a chair, back straight, hinge from the hips.',
      seconds: 45,
      category: ExerciseCategory.stretch,
      emoji: '🦵',
    ),

    // Mobility
    Exercise(
      id: 'cat_cow',
      name: 'Cat–cow',
      instruction: 'On all fours: inhale arch down, exhale round up.',
      seconds: 45,
      category: ExerciseCategory.mobility,
      emoji: '🐈',
    ),
    Exercise(
      id: 'hip_circles',
      name: 'Hip circles',
      instruction: 'Stand wide, draw big circles with your hips.',
      seconds: 30,
      category: ExerciseCategory.mobility,
      emoji: '🌀',
    ),
    Exercise(
      id: 'ankle_circles',
      name: 'Ankle circles',
      instruction: 'Balance on one leg, circle the foot both ways.',
      seconds: 30,
      category: ExerciseCategory.mobility,
      emoji: '🦶',
    ),
    Exercise(
      id: 'spine_twist',
      name: 'Spine twist',
      instruction: 'Seated, rotate your torso side to side, shoulders relaxed.',
      seconds: 40,
      category: ExerciseCategory.mobility,
      emoji: '🌪️',
    ),
    Exercise(
      id: 'wrist_mobility',
      name: 'Wrist mobility',
      instruction: 'Circles, flexion and extension — perfect after mouse work.',
      seconds: 30,
      category: ExerciseCategory.mobility,
      emoji: '✋',
    ),
    Exercise(
      id: 'thoracic_open',
      name: 'Thoracic opener',
      instruction: 'Quadruped, hand behind head, rotate to open the chest.',
      seconds: 40,
      category: ExerciseCategory.mobility,
      emoji: '🦋',
    ),

    // Breath
    Exercise(
      id: 'box_breath',
      name: 'Box breathing',
      instruction: 'Inhale 4 — hold 4 — exhale 4 — hold 4.',
      seconds: 60,
      category: ExerciseCategory.breath,
      emoji: '🫁',
    ),
    Exercise(
      id: '4_7_8',
      name: '4-7-8 breathing',
      instruction: 'Inhale 4 through nose, hold 7, exhale 8 through mouth.',
      seconds: 75,
      category: ExerciseCategory.breath,
      emoji: '🌬️',
    ),
    Exercise(
      id: 'belly_breath',
      name: 'Belly breathing',
      instruction: 'Hand on the belly — deep inhale into the belly, long exhale.',
      seconds: 60,
      category: ExerciseCategory.breath,
      emoji: '💨',
    ),
    Exercise(
      id: 'alternate_nostril',
      name: 'Alternate nostril',
      instruction: 'Inhale through one nostril, exhale through the other.',
      seconds: 60,
      category: ExerciseCategory.breath,
      emoji: '🧠',
    ),

    // Cardio
    Exercise(
      id: 'march_in_place',
      name: 'March in place',
      instruction: 'High knees, drive the arms with energy.',
      seconds: 45,
      category: ExerciseCategory.cardio,
      emoji: '🚶',
    ),
    Exercise(
      id: 'jumping_jacks',
      name: 'Jumping jacks',
      instruction: 'Classic jumping jacks — arms up, legs wide.',
      seconds: 40,
      category: ExerciseCategory.cardio,
      emoji: '🤾',
    ),
    Exercise(
      id: 'high_knees',
      name: 'High knees',
      instruction: 'Run in place, knees up to hip height.',
      seconds: 30,
      category: ExerciseCategory.cardio,
      emoji: '🏃',
    ),
    Exercise(
      id: 'squat_pulse',
      name: 'Squat pulse',
      instruction: 'Low squat, small pulses — feel your legs work.',
      seconds: 35,
      category: ExerciseCategory.cardio,
      emoji: '🏋️',
    ),
    Exercise(
      id: 'shadow_box',
      name: 'Shadow boxing',
      instruction: 'Light footwork, alternating punches — stay loose.',
      seconds: 45,
      category: ExerciseCategory.cardio,
      emoji: '🥊',
    ),
  ];

  static List<Exercise> byCategory(ExerciseCategory c) =>
      all.where((e) => e.category == c).toList();

  static Exercise byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => all.first);

  static const List<WorkoutPlan> featuredPlans = [
    WorkoutPlan(
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
          id: 'chest_opener',
          name: 'Chest opener',
          instruction: 'Clasp hands behind your back.',
          seconds: 45,
          category: ExerciseCategory.stretch,
          emoji: '🧘',
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
    WorkoutPlan(
      title: 'Energy boost',
      subtitle: '4 min — cardio + mobility',
      primaryCategory: ExerciseCategory.cardio,
      exercises: [
        Exercise(
          id: 'march_in_place',
          name: 'March in place',
          instruction: 'High knees, energetic arms.',
          seconds: 45,
          category: ExerciseCategory.cardio,
          emoji: '🚶',
        ),
        Exercise(
          id: 'jumping_jacks',
          name: 'Jumping jacks',
          instruction: 'Arms up, legs wide.',
          seconds: 40,
          category: ExerciseCategory.cardio,
          emoji: '🤾',
        ),
        Exercise(
          id: 'high_knees',
          name: 'High knees',
          instruction: 'Run in place.',
          seconds: 30,
          category: ExerciseCategory.cardio,
          emoji: '🏃',
        ),
        Exercise(
          id: 'hip_circles',
          name: 'Hip circles',
          instruction: 'Stand wide, draw big circles.',
          seconds: 30,
          category: ExerciseCategory.mobility,
          emoji: '🌀',
        ),
        Exercise(
          id: 'spine_twist',
          name: 'Spine twist',
          instruction: 'Rotate your torso side to side.',
          seconds: 35,
          category: ExerciseCategory.mobility,
          emoji: '🌪️',
        ),
      ],
    ),
    WorkoutPlan(
      title: 'Wind-down',
      subtitle: '5 min — breath and reset',
      primaryCategory: ExerciseCategory.breath,
      exercises: [
        Exercise(
          id: 'belly_breath',
          name: 'Belly breathing',
          instruction: 'Hand on the belly, long exhales.',
          seconds: 60,
          category: ExerciseCategory.breath,
          emoji: '💨',
        ),
        Exercise(
          id: '4_7_8',
          name: '4-7-8 breathing',
          instruction: 'Inhale 4 — hold 7 — exhale 8.',
          seconds: 75,
          category: ExerciseCategory.breath,
          emoji: '🌬️',
        ),
        Exercise(
          id: 'forward_fold',
          name: 'Forward fold',
          instruction: 'Slowly roll the spine down.',
          seconds: 45,
          category: ExerciseCategory.stretch,
          emoji: '🙇',
        ),
        Exercise(
          id: 'alternate_nostril',
          name: 'Alternate nostril',
          instruction: 'Calm the nervous system.',
          seconds: 60,
          category: ExerciseCategory.breath,
          emoji: '🧠',
        ),
      ],
    ),
  ];

  static WorkoutPlan recommendedFor(ActivityProfile profile, DateTime now) {
    final hour = now.hour;
    if (profile == ActivityProfile.recovery) {
      return featuredPlans[2];
    }
    if (profile == ActivityProfile.active) {
      return featuredPlans[1];
    }
    // Sedentary — switch by time of day.
    if (hour < 12) return featuredPlans[1];
    if (hour < 18) return featuredPlans[0];
    return featuredPlans[2];
  }

  static WorkoutPlan buildQuickPlan(ExerciseCategory category,
      {int targetSeconds = 180}) {
    final pool = byCategory(category);
    final exercises = <Exercise>[];
    int total = 0;
    int idx = 0;
    while (total < targetSeconds && exercises.length < 6) {
      final ex = pool[idx % pool.length];
      exercises.add(ex);
      total += ex.seconds;
      idx++;
    }
    return WorkoutPlan(
      title: 'Quick ${category.label.toLowerCase()} session',
      subtitle: '${(total / 60).ceil()} min — ${exercises.length} exercises',
      primaryCategory: category,
      exercises: exercises,
    );
  }
}
