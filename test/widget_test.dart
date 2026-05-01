import 'package:flutter_test/flutter_test.dart';

import 'package:movemate/exercise_library.dart';
import 'package:movemate/models.dart';

void main() {
  test('exercise library has at least 4 plans/categories', () {
    expect(ExerciseLibrary.featuredPlans, isNotEmpty);
    expect(ExerciseLibrary.all.length, greaterThanOrEqualTo(20));
    for (final cat in ExerciseCategory.values) {
      expect(ExerciseLibrary.byCategory(cat), isNotEmpty);
    }
  });

  test('quick plan stays close to target duration', () {
    final plan = ExerciseLibrary.buildQuickPlan(
      ExerciseCategory.stretch,
      targetSeconds: 120,
    );
    expect(plan.exercises, isNotEmpty);
    expect(plan.totalSeconds, greaterThanOrEqualTo(120));
  });
}
