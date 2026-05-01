import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class Storage {
  static const _kProfile = 'profile';
  static const _kReminderInterval = 'reminderIntervalHours';
  static const _kDailyGoal = 'dailyGoalMinutes';
  static const _kSessions = 'sessions';
  static const _kOnboarded = 'onboarded';
  static const _kSeenAchievements = 'seenAchievements';

  final SharedPreferences _prefs;

  Storage(this._prefs);

  static Future<Storage> open() async {
    final prefs = await SharedPreferences.getInstance();
    return Storage(prefs);
  }

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded(bool v) async {
    await _prefs.setBool(_kOnboarded, v);
  }

  ActivityProfile get profile {
    final idx = _prefs.getInt(_kProfile) ?? ActivityProfile.sedentary.index;
    return ActivityProfile.values[idx];
  }

  Future<void> setProfile(ActivityProfile profile) async {
    await _prefs.setInt(_kProfile, profile.index);
  }

  int get reminderIntervalHours => _prefs.getInt(_kReminderInterval) ?? 2;
  Future<void> setReminderIntervalHours(int hours) async {
    await _prefs.setInt(_kReminderInterval, hours);
  }

  int get dailyGoalMinutes => _prefs.getInt(_kDailyGoal) ?? 10;
  Future<void> setDailyGoalMinutes(int minutes) async {
    await _prefs.setInt(_kDailyGoal, minutes);
  }

  List<SessionRecord> get sessions {
    final raw = _prefs.getStringList(_kSessions) ?? const [];
    return raw
        .map((s) => SessionRecord.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addSession(SessionRecord record) async {
    final list = sessions..add(record);
    list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final encoded = list.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_kSessions, encoded);
  }

  Future<void> clearSessions() async {
    await _prefs.remove(_kSessions);
    await _prefs.remove(_kSeenAchievements);
  }

  Set<String> get seenAchievements =>
      (_prefs.getStringList(_kSeenAchievements) ?? const []).toSet();

  Future<void> markAchievementsSeen(Iterable<String> ids) async {
    final updated = seenAchievements..addAll(ids);
    await _prefs.setStringList(_kSeenAchievements, updated.toList());
  }

  /// Bieżący streak (kolejne dni z co najmniej jedną ukończoną sesją).
  int get currentStreak {
    final all = sessions;
    if (all.isEmpty) return 0;
    final today = DateTime.now();
    final todayKey = _dayKey(today);
    final completedDays = all.map((s) => _dayKey(s.completedAt)).toSet();

    int streak = 0;
    DateTime cursor = today;
    // Jeśli dziś nic nie zrobiono — zacznij od wczoraj, by streak nie zerował się przed wieczorem.
    if (!completedDays.contains(todayKey)) {
      cursor = today.subtract(const Duration(days: 1));
    }
    while (completedDays.contains(_dayKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get todayMinutes {
    final today = DateTime.now();
    final key = _dayKey(today);
    final secs = sessions
        .where((s) => _dayKey(s.completedAt) == key)
        .fold<int>(0, (sum, s) => sum + s.seconds);
    return (secs / 60).round();
  }

  int get weekMinutes {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final secs = sessions
        .where((s) => s.completedAt.isAfter(cutoff))
        .fold<int>(0, (sum, s) => sum + s.seconds);
    return (secs / 60).round();
  }

  /// Mapa: dzień (YYYY-MM-DD) → łączne minuty, dla ostatnich [days] dni.
  Map<String, int> minutesByDay({int days = 30}) {
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      result[_dayKey(d)] = 0;
    }
    for (final s in sessions) {
      final key = _dayKey(s.completedAt);
      if (result.containsKey(key)) {
        result[key] = (result[key] ?? 0) + (s.seconds / 60).round();
      }
    }
    return result;
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
