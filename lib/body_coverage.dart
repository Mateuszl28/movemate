import 'exercise_library.dart';
import 'models.dart';

class BodyCoverage {
  final Map<BodyArea, int> secondsByArea;

  const BodyCoverage(this.secondsByArea);

  factory BodyCoverage.lastWeek(List<SessionRecord> sessions, DateTime now) {
    // Sessions store the plan/category but not which specific exercises ran.
    // For coverage, we treat each session as if it ran a representative
    // sample of its category for the recorded duration, distributing seconds
    // across the body areas tagged on that category's exercises.
    final cutoff = now.subtract(const Duration(days: 7));
    final result = <BodyArea, int>{};
    for (final s in sessions) {
      if (s.completedAt.isBefore(cutoff)) continue;
      final pool = ExerciseLibrary.byCategory(s.category);
      if (pool.isEmpty) continue;
      final allAreas = <BodyArea>{};
      for (final e in pool) {
        allAreas.addAll(e.bodyAreas);
      }
      if (allAreas.isEmpty) continue;
      final perArea = (s.seconds / allAreas.length).round();
      for (final a in allAreas) {
        result.update(a, (v) => v + perArea, ifAbsent: () => perArea);
      }
    }
    return BodyCoverage(result);
  }

  int minutesFor(BodyArea a) =>
      ((secondsByArea[a] ?? 0) / 60).round();

  int get totalSeconds =>
      secondsByArea.values.fold<int>(0, (sum, v) => sum + v);

  int get areasWorked =>
      secondsByArea.entries.where((e) => e.value > 0).length;

  /// Areas that haven't been worked at all this week (excluding fullBody &
  /// breath which are too general / always-available).
  List<BodyArea> get neglected {
    final exclude = {BodyArea.fullBody};
    return BodyArea.values
        .where((a) =>
            !exclude.contains(a) &&
            (secondsByArea[a] ?? 0) == 0)
        .toList();
  }
}
