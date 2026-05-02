import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movemate/adaptive_plan.dart';
import 'package:movemate/demo_seeder.dart';
import 'package:movemate/models.dart';
import 'package:movemate/storage.dart';

Future<Storage> _loadSeeded(DateTime now) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await Storage.open();
  await storage.replaceWithImport(DemoSeeder.generate(now: now));
  return storage;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DemoSeeder', () {
    test('produces enough sessions to fill the dashboard', () async {
      final storage = await _loadSeeded(DateTime(2026, 5, 5, 12));
      // ~25 sessions across 30 days; allow some variance.
      expect(storage.sessions.length, greaterThan(20));
      expect(storage.onboarded, isTrue);
    });

    test('back pain trends down over the 14-day window', () async {
      final storage = await _loadSeeded(DateTime(2026, 5, 5, 12));
      final series = storage.painSeries(BodyArea.back);
      // Find first and last non-null reading.
      final nonNull =
          series.where((v) => v != null).cast<int>().toList();
      expect(nonNull.length, greaterThanOrEqualTo(10));
      expect(nonNull.first, greaterThan(nonNull.last),
          reason: 'back pain should have improved');
    });

    test('sleep, energy, hydration, and posture all populate', () async {
      final storage = await _loadSeeded(DateTime(2026, 5, 5, 12));
      expect(storage.latestSleep, isNotNull);
      expect(storage.latestEnergy, isNotNull);
      expect(storage.glassesToday, greaterThan(0));
      expect(storage.latestPostureScore, equals(84));
    });

    test('seeded data drives the adaptive plan into a relief day',
        () async {
      final storage = await _loadSeeded(DateTime(2026, 5, 5, 12));
      final plan = AdaptivePlan.build(storage);
      expect(plan.days.any((d) => d.theme == 'Pain relief'), isTrue);
    });
  });
}
