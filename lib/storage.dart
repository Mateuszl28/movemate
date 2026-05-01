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
  static const _kFreezesAvailable = 'freezesAvailable';
  static const _kUsedFreezeDates = 'usedFreezeDates';
  static const _kLastFreezeMilestone = 'lastFreezeMilestone';
  static const _kLastWeeklyReview = 'lastWeeklyReview';
  static const _kLastCelebratedStreak = 'lastCelebratedStreak';
  static const _kThemeMode = 'themeMode'; // 0 = system, 1 = light, 2 = dark

  static const int maxFreezes = 3;

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
    await _prefs.remove(_kFreezesAvailable);
    await _prefs.remove(_kUsedFreezeDates);
    await _prefs.remove(_kLastFreezeMilestone);
  }

  int get freezesAvailable => _prefs.getInt(_kFreezesAvailable) ?? 0;
  Future<void> _setFreezesAvailable(int v) async {
    await _prefs.setInt(_kFreezesAvailable, v.clamp(0, maxFreezes));
  }

  Set<String> get usedFreezeDates =>
      (_prefs.getStringList(_kUsedFreezeDates) ?? const []).toSet();
  Future<void> _addUsedFreezeDate(String dayKey) async {
    final updated = usedFreezeDates..add(dayKey);
    await _prefs.setStringList(_kUsedFreezeDates, updated.toList());
  }

  int get _lastFreezeMilestone =>
      _prefs.getInt(_kLastFreezeMilestone) ?? 0;
  Future<void> _setLastFreezeMilestone(int v) async {
    await _prefs.setInt(_kLastFreezeMilestone, v);
  }

  String? get lastWeeklyReviewIso =>
      _prefs.getString(_kLastWeeklyReview);
  Future<void> setLastWeeklyReviewIso(String iso) async {
    await _prefs.setString(_kLastWeeklyReview, iso);
  }

  int get lastCelebratedStreak =>
      _prefs.getInt(_kLastCelebratedStreak) ?? 0;
  Future<void> setLastCelebratedStreak(int v) async {
    await _prefs.setInt(_kLastCelebratedStreak, v);
  }

  int get themeModeIndex => _prefs.getInt(_kThemeMode) ?? 0;
  Future<void> setThemeModeIndex(int v) async {
    await _prefs.setInt(_kThemeMode, v);
  }

  /// Grants freezes when the user crosses a 7-day streak boundary that we
  /// haven't rewarded yet. Returns the number of newly granted freezes.
  Future<int> grantFreezesForStreak() async {
    final streak = currentStreak;
    final milestonesReached = streak ~/ 7;
    final lastMilestone = _lastFreezeMilestone;
    if (milestonesReached <= lastMilestone) return 0;
    final earned = milestonesReached - lastMilestone;
    final newTotal = (freezesAvailable + earned).clamp(0, maxFreezes);
    await _setFreezesAvailable(newTotal);
    await _setLastFreezeMilestone(milestonesReached);
    return earned;
  }

  /// Walks backward from yesterday and consumes freezes for any missed days
  /// until the streak hits an unbroken span.
  Future<void> maintainStreakWithFreezes() async {
    if (freezesAvailable <= 0) return;
    final sessionDays = sessions.map((s) => _dayKey(s.completedAt)).toSet();
    final today = DateTime.now();
    var cursor = today.subtract(const Duration(days: 1));
    int budget = freezesAvailable;

    // Cap how far back we'll patch (avoid resurrecting ancient streaks).
    for (int i = 0; i < 30 && budget > 0; i++) {
      final key = _dayKey(cursor);
      if (sessionDays.contains(key) || usedFreezeDates.contains(key)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      // Only patch the first contiguous gap right behind the current streak.
      // If we already encountered a "fully broken" day with no freeze and no
      // session, stop.
      await _addUsedFreezeDate(key);
      budget -= 1;
      await _setFreezesAvailable(budget);
      cursor = cursor.subtract(const Duration(days: 1));
    }
  }

  Set<String> get seenAchievements =>
      (_prefs.getStringList(_kSeenAchievements) ?? const []).toSet();

  Future<void> markAchievementsSeen(Iterable<String> ids) async {
    final updated = seenAchievements..addAll(ids);
    await _prefs.setStringList(_kSeenAchievements, updated.toList());
  }

  /// Bieżący streak — kolejne dni z co najmniej jedną ukończoną sesją lub
  /// zużytym streak-freezem.
  int get currentStreak {
    final all = sessions;
    if (all.isEmpty && usedFreezeDates.isEmpty) return 0;
    final today = DateTime.now();
    final todayKey = _dayKey(today);
    final completedDays = all.map((s) => _dayKey(s.completedAt)).toSet();
    final freezeDays = usedFreezeDates;

    bool isCovered(String key) =>
        completedDays.contains(key) || freezeDays.contains(key);

    int streak = 0;
    DateTime cursor = today;
    // Jeśli dziś jeszcze nic nie zrobiono — startuj od wczoraj, żeby streak
    // nie zerował się przed wieczorem.
    if (!isCovered(todayKey)) {
      cursor = today.subtract(const Duration(days: 1));
    }
    while (isCovered(_dayKey(cursor))) {
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
