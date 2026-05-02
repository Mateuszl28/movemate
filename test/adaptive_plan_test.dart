import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movemate/adaptive_plan.dart';
import 'package:movemate/models.dart';
import 'package:movemate/storage.dart';

Future<Storage> _freshStorage() async {
  SharedPreferences.setMockInitialValues({});
  return Storage.open();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdaptivePlan', () {
    test('produces seven days for a brand-new user', () async {
      final storage = await _freshStorage();
      final plan = AdaptivePlan.build(storage);
      expect(plan.days, hasLength(7));
    });

    test('today appears as the first day', () async {
      final storage = await _freshStorage();
      final now = DateTime(2026, 5, 5, 9);
      final plan = AdaptivePlan.build(storage, from: now);
      expect(plan.days.first.date.day, 5);
      expect(plan.days.first.date.month, 5);
    });

    test('hot pain area drives a pain-relief themed day', () async {
      final storage = await _freshStorage();
      // Log strong neck pain today.
      await storage.logPain(BodyArea.neck, 8);
      final plan = AdaptivePlan.build(storage);
      final hasReliefDay =
          plan.days.any((d) => d.theme == 'Pain relief');
      expect(hasReliefDay, isTrue,
          reason: 'expected pain relief day when an area is hot');
    });

    test('low sleep removes early cardio in the rotation', () async {
      final storage = await _freshStorage();
      await storage.setProfile(ActivityProfile.active);
      // Active rotation starts with cardio on day 0; flag short sleep.
      await storage.logSleep(4.5, 2);
      final plan = AdaptivePlan.build(storage);
      // Day 0 and day 1 must not be cardio.
      expect(plan.days[0].plan.primaryCategory,
          isNot(equals(ExerciseCategory.cardio)));
      expect(plan.days[1].plan.primaryCategory,
          isNot(equals(ExerciseCategory.cardio)));
    });
  });
}
