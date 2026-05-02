import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movemate/models.dart';
import 'package:movemate/storage.dart';

Future<Storage> _freshStorage([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return Storage.open();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Storage · pain log', () {
    test('logging pain stores by area and round-trips', () async {
      final storage = await _freshStorage();
      await storage.logPain(BodyArea.back, 7);
      await storage.logPain(BodyArea.neck, 3);
      final today = storage.painToday;
      expect(today[BodyArea.back], 7);
      expect(today[BodyArea.neck], 3);
    });

    test('logging the same area replaces the prior level', () async {
      final storage = await _freshStorage();
      await storage.logPain(BodyArea.back, 5);
      await storage.logPain(BodyArea.back, 9);
      expect(storage.painToday[BodyArea.back], 9);
    });

    test('hotPainAreas surfaces areas at or above threshold', () async {
      final storage = await _freshStorage();
      await storage.logPain(BodyArea.back, 8);
      await storage.logPain(BodyArea.wrists, 2);
      final hot = storage.hotPainAreas();
      expect(hot, contains(BodyArea.back));
      expect(hot, isNot(contains(BodyArea.wrists)));
    });

    test('clearing pain removes the entry for today', () async {
      final storage = await _freshStorage();
      await storage.logPain(BodyArea.hips, 5);
      await storage.clearPain(BodyArea.hips);
      expect(storage.painToday.containsKey(BodyArea.hips), isFalse);
    });

    test('painSeries returns one slot per day with nulls for gaps',
        () async {
      final storage = await _freshStorage();
      await storage.logPain(BodyArea.back, 4);
      final series = storage.painSeries(BodyArea.back, days: 14);
      expect(series, hasLength(14));
      // Today is the last entry — should be 4.
      expect(series.last, 4);
      // Earlier days had no entry — null.
      expect(series.first, isNull);
    });
  });

  group('Storage · sleep log', () {
    test('latestSleep returns the most recent entry', () async {
      final storage = await _freshStorage();
      await storage.logSleep(7.5, 4);
      final latest = storage.latestSleep!;
      expect(latest.hours, 7.5);
      expect(latest.quality, 4);
    });

    test('sleepAverageHours returns null with no data', () async {
      final storage = await _freshStorage();
      expect(storage.sleepAverageHours(), isNull);
    });
  });

  group('Storage · quiet hours', () {
    test('default window covers 22:00..08:00 (wraps midnight)', () async {
      final storage = await _freshStorage();
      // Defaults: 22 → 8.
      expect(storage.isHourQuiet(0), isTrue);
      expect(storage.isHourQuiet(7), isTrue);
      expect(storage.isHourQuiet(8), isFalse);
      expect(storage.isHourQuiet(15), isFalse);
      expect(storage.isHourQuiet(22), isTrue);
      expect(storage.isHourQuiet(23), isTrue);
    });

    test('non-wrapping window only covers its inner range', () async {
      final storage = await _freshStorage();
      await storage.setQuietHours(13, 16);
      expect(storage.isHourQuiet(12), isFalse);
      expect(storage.isHourQuiet(13), isTrue);
      expect(storage.isHourQuiet(15), isTrue);
      expect(storage.isHourQuiet(16), isFalse);
    });

    test('start == end disables quiet hours', () async {
      final storage = await _freshStorage();
      await storage.setQuietHours(10, 10);
      for (int h = 0; h < 24; h++) {
        expect(storage.isHourQuiet(h), isFalse);
      }
    });
  });
}
