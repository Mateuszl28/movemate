import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'movemate_reminders';
  static const _channelName = 'Movement reminders';
  static const _channelDescription =
      'Gentle nudges to take a quick movement break.';

  // Notification IDs reserved for our recurring reminders. We use a fixed set
  // and fully reschedule every time settings change.
  static const _reminderIdBase = 1000;

  static const List<String> _messages = [
    "Time to move! A 2-minute reset is waiting.",
    "Posture check — quick mobility break?",
    "Breathe deep. One minute can change your day.",
    "Stand up and stretch — your back will thank you.",
    "Tiny break, big difference. Let's move.",
  ];

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fallback — keep the default UTC location if device lookup fails.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
      await androidImpl?.requestNotificationsPermission();
    }
    _initialized = true;
  }

  Future<void> cancelAll() async {
    if (!_initialized) await init();
    await _plugin.cancelAll();
  }

  /// Schedules one daily-repeating notification per slot, starting from the
  /// next slot in the future. Slots are every [intervalHours] hours between
  /// 09:00 and 20:00 (inclusive of both bounds when divisible).
  Future<void> scheduleReminders(int intervalHours) async {
    if (!_initialized) await init();
    await _plugin.cancelAll();

    final slots = <int>[];
    for (int h = 9; h <= 20; h += intervalHours) {
      slots.add(h);
    }

    final now = tz.TZDateTime.now(tz.local);
    for (int i = 0; i < slots.length; i++) {
      final hour = slots[i];
      var firstFire = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, 0);
      if (firstFire.isBefore(now)) {
        firstFire = firstFire.add(const Duration(days: 1));
      }
      final message = _messages[i % _messages.length];
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );
      await _plugin.zonedSchedule(
        _reminderIdBase + i,
        'MoveMate',
        message,
        firstFire,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
