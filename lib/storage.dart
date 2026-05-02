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
  static const _kCoachPersonality = 'coachPersonality'; // 0 = calm, 1 = upbeat, 2 = strict
  static const _kHydrationGoal = 'hydrationGoal';
  static const _kHydrationLog = 'hydrationLog'; // JSON map: YYYY-MM-DD -> int
  static const _kEyeBreaksLog = 'eyeBreaksLog'; // JSON map: YYYY-MM-DD -> int
  static const _kPostureLog = 'postureLog';     // JSON map: YYYY-MM-DD -> List<int>
  static const _kQuietStart = 'quietHoursStart'; // 0..23
  static const _kQuietEnd = 'quietHoursEnd';     // 0..23
  static const _kEnergyLog = 'energyLog';        // JSON map: YYYY-MM-DD -> List<int>
  static const _kSleepLog = 'sleepLog';          // JSON map: YYYY-MM-DD -> {h, q}
  static const _kMindfulLog = 'mindfulLog';      // JSON map: YYYY-MM-DD -> int

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
    await _prefs.remove(_kEyeBreaksLog);
    await _prefs.remove(_kPostureLog);
    await _prefs.remove(_kEnergyLog);
    await _prefs.remove(_kSleepLog);
    await _prefs.remove(_kMindfulLog);
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

  int get coachPersonalityIndex => _prefs.getInt(_kCoachPersonality) ?? 0;
  Future<void> setCoachPersonalityIndex(int v) async {
    await _prefs.setInt(_kCoachPersonality, v);
  }

  int get hydrationGoalGlasses => _prefs.getInt(_kHydrationGoal) ?? 8;
  Future<void> setHydrationGoalGlasses(int v) async {
    await _prefs.setInt(_kHydrationGoal, v);
  }

  Map<String, int> get hydrationLog {
    final raw = _prefs.getString(_kHydrationLog);
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  Future<void> _writeHydrationLog(Map<String, int> log) async {
    await _prefs.setString(_kHydrationLog, jsonEncode(log));
  }

  int get glassesToday {
    final key = _dayKey(DateTime.now());
    return hydrationLog[key] ?? 0;
  }

  Future<void> addGlass() async {
    final log = Map<String, int>.from(hydrationLog);
    final key = _dayKey(DateTime.now());
    log[key] = (log[key] ?? 0) + 1;
    await _writeHydrationLog(log);
  }

  Future<void> removeGlass() async {
    final log = Map<String, int>.from(hydrationLog);
    final key = _dayKey(DateTime.now());
    final cur = log[key] ?? 0;
    if (cur <= 1) {
      log.remove(key);
    } else {
      log[key] = cur - 1;
    }
    await _writeHydrationLog(log);
  }

  Map<String, int> hydrationByDay({int days = 7}) {
    final result = <String, int>{};
    final now = DateTime.now();
    final log = hydrationLog;
    for (int i = 0; i < days; i++) {
      final d = now.subtract(Duration(days: i));
      final key = _dayKey(d);
      result[key] = log[key] ?? 0;
    }
    return result;
  }

  Map<String, int> get eyeBreaksLog {
    final raw = _prefs.getString(_kEyeBreaksLog);
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  int get eyeBreaksToday => eyeBreaksLog[_dayKey(DateTime.now())] ?? 0;

  int get eyeBreaksWeek {
    final log = eyeBreaksLog;
    final now = DateTime.now();
    int total = 0;
    for (int i = 0; i < 7; i++) {
      final key = _dayKey(now.subtract(Duration(days: i)));
      total += log[key] ?? 0;
    }
    return total;
  }

  Future<void> logEyeBreak() async {
    final log = Map<String, int>.from(eyeBreaksLog);
    final key = _dayKey(DateTime.now());
    log[key] = (log[key] ?? 0) + 1;
    await _prefs.setString(_kEyeBreaksLog, jsonEncode(log));
  }

  Map<String, List<int>> get postureLog {
    final raw = _prefs.getString(_kPostureLog);
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(
        k, (v as List).map((e) => (e as num).toInt()).toList()));
  }

  /// Most recent posture-check score (0..100), or null if never run.
  int? get latestPostureScore {
    final log = postureLog;
    if (log.isEmpty) return null;
    final keys = log.keys.toList()..sort();
    final latest = log[keys.last];
    if (latest == null || latest.isEmpty) return null;
    return latest.last;
  }

  /// Highest posture score ever logged (0..100), or null if never run.
  int? get bestPostureScore {
    final log = postureLog;
    if (log.isEmpty) return null;
    int best = -1;
    for (final scores in log.values) {
      for (final s in scores) {
        if (s > best) best = s;
      }
    }
    return best < 0 ? null : best;
  }

  bool get hasRunPostureCheck => postureLog.isNotEmpty;

  /// Daily sleep log — hours slept (double) plus subjective quality (1..5).
  /// One entry per day; logging again replaces the prior entry.
  Map<String, SleepEntry> get sleepLog {
    final raw = _prefs.getString(_kSleepLog);
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) {
      final m = v as Map<String, dynamic>;
      return MapEntry(
        k,
        SleepEntry(
          hours: (m['h'] as num).toDouble(),
          quality: (m['q'] as num).toInt(),
        ),
      );
    });
  }

  SleepEntry? get latestSleep {
    final log = sleepLog;
    if (log.isEmpty) return null;
    final keys = log.keys.toList()..sort();
    return log[keys.last];
  }

  Future<void> logSleep(double hours, int quality) async {
    final log = Map<String, SleepEntry>.from(sleepLog);
    final key = _dayKey(DateTime.now());
    log[key] = SleepEntry(hours: hours, quality: quality);
    final encoded = log.map(
        (k, v) => MapEntry(k, {'h': v.hours, 'q': v.quality}));
    await _prefs.setString(_kSleepLog, jsonEncode(encoded));
  }

  /// Number of sleep entries logged in the last [days] days.
  int sleepEntriesInLastDays({int days = 7}) {
    final log = sleepLog;
    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < days; i++) {
      final key = _dayKey(now.subtract(Duration(days: i)));
      if (log.containsKey(key)) count += 1;
    }
    return count;
  }

  bool get hasAnyMindfulMoment => mindfulLog.isNotEmpty;

  /// Average hours slept across the last [days] days that have an entry.
  /// Returns null if no entries fall in the window.
  double? sleepAverageHours({int days = 7}) {
    final log = sleepLog;
    if (log.isEmpty) return null;
    final now = DateTime.now();
    double sum = 0;
    int count = 0;
    for (int i = 0; i < days; i++) {
      final key = _dayKey(now.subtract(Duration(days: i)));
      final entry = log[key];
      if (entry == null) continue;
      sum += entry.hours;
      count += 1;
    }
    if (count == 0) return null;
    return sum / count;
  }

  /// Mindfulness moments completed per day.
  Map<String, int> get mindfulLog {
    final raw = _prefs.getString(_kMindfulLog);
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
  }

  int get mindfulToday => mindfulLog[_dayKey(DateTime.now())] ?? 0;

  int get mindfulWeek {
    final log = mindfulLog;
    final now = DateTime.now();
    int total = 0;
    for (int i = 0; i < 7; i++) {
      final key = _dayKey(now.subtract(Duration(days: i)));
      total += log[key] ?? 0;
    }
    return total;
  }

  Future<void> logMindfulMoment() async {
    final log = Map<String, int>.from(mindfulLog);
    final key = _dayKey(DateTime.now());
    log[key] = (log[key] ?? 0) + 1;
    await _prefs.setString(_kMindfulLog, jsonEncode(log));
  }

  /// Returns a JSON-encoded snapshot of every key currently stored. Includes a
  /// version + timestamp so future imports can validate the payload. Lists are
  /// preserved as native JSON arrays.
  String exportAll() {
    final out = <String, dynamic>{
      '__movemate__': 1,
      '__exportedAt__': DateTime.now().toIso8601String(),
      'data': <String, dynamic>{
        for (final key in _prefs.getKeys()) key: _prefs.get(key),
      },
    };
    return jsonEncode(out);
  }

  /// Quiet hours: notifications are skipped when the slot's hour falls inside
  /// [quietHoursStart, quietHoursEnd). The window may wrap past midnight
  /// (e.g. 22 → 8 means 22:00..23:59 plus 00:00..07:59 are quiet).
  int get quietHoursStart => _prefs.getInt(_kQuietStart) ?? 22;
  int get quietHoursEnd => _prefs.getInt(_kQuietEnd) ?? 8;

  Future<void> setQuietHours(int start, int end) async {
    await _prefs.setInt(_kQuietStart, start.clamp(0, 23));
    await _prefs.setInt(_kQuietEnd, end.clamp(0, 23));
  }

  bool isHourQuiet(int hour) {
    final s = quietHoursStart;
    final e = quietHoursEnd;
    if (s == e) return false; // disabled
    if (s < e) return hour >= s && hour < e;
    // Wraps midnight.
    return hour >= s || hour < e;
  }

  /// Daily energy check-ins (1..5). Multiple per day are allowed; the latest
  /// is what UI surfaces.
  Map<String, List<int>> get energyLog {
    final raw = _prefs.getString(_kEnergyLog);
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(
        k, (v as List).map((e) => (e as num).toInt()).toList()));
  }

  int? get latestEnergy {
    final log = energyLog;
    final key = _dayKey(DateTime.now());
    final today = log[key];
    if (today != null && today.isNotEmpty) return today.last;
    if (log.isEmpty) return null;
    final keys = log.keys.toList()..sort();
    final fallback = log[keys.last];
    return (fallback == null || fallback.isEmpty) ? null : fallback.last;
  }

  Future<void> logEnergy(int level) async {
    final log = Map<String, List<int>>.from(
        energyLog.map((k, v) => MapEntry(k, List<int>.from(v))));
    final key = _dayKey(DateTime.now());
    final list = log[key] ?? <int>[];
    list.add(level.clamp(1, 5));
    log[key] = list;
    await _prefs.setString(_kEnergyLog, jsonEncode(log));
  }

  /// Average posture score over the last [days] days (0..100), or null if no data.
  int? postureAverage({int days = 7}) {
    final log = postureLog;
    if (log.isEmpty) return null;
    final now = DateTime.now();
    int sum = 0;
    int count = 0;
    for (int i = 0; i < days; i++) {
      final key = _dayKey(now.subtract(Duration(days: i)));
      final scores = log[key];
      if (scores == null) continue;
      for (final s in scores) {
        sum += s;
        count += 1;
      }
    }
    if (count == 0) return null;
    return (sum / count).round();
  }

  Future<void> logPosture(int score) async {
    final log = Map<String, List<int>>.from(postureLog
        .map((k, v) => MapEntry(k, List<int>.from(v))));
    final key = _dayKey(DateTime.now());
    final list = log[key] ?? <int>[];
    list.add(score.clamp(0, 100));
    log[key] = list;
    await _prefs.setString(_kPostureLog, jsonEncode(log));
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

class SleepEntry {
  final double hours;
  final int quality; // 1..5
  const SleepEntry({required this.hours, required this.quality});
}
