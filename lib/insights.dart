import 'models.dart';

class DayBar {
  final DateTime date;
  final int minutes;
  final String label; // e.g., 'Mon'
  const DayBar(
      {required this.date, required this.minutes, required this.label});
}

class WeeklyInsights {
  final List<DayBar> last7Days;
  final int totalMinutes;
  final double averagePerDay;
  final int activeDays;
  final DayBar? strongestDay;
  final ExerciseCategory? topCategory;
  final List<ExerciseCategory> missedCategoriesThisWeek;
  final double averageSessionMinutes;
  final double? averageMoodDelta;
  final int moodTrackedSessions;
  final List<String> bullets;

  const WeeklyInsights({
    required this.last7Days,
    required this.totalMinutes,
    required this.averagePerDay,
    required this.activeDays,
    required this.strongestDay,
    required this.topCategory,
    required this.missedCategoriesThisWeek,
    required this.averageSessionMinutes,
    required this.averageMoodDelta,
    required this.moodTrackedSessions,
    required this.bullets,
  });

  factory WeeklyInsights.from(List<SessionRecord> sessions) {
    final now = DateTime.now();
    final days = <DayBar>[];
    for (int i = 6; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final mins = sessions
          .where((s) =>
              s.completedAt.year == d.year &&
              s.completedAt.month == d.month &&
              s.completedAt.day == d.day)
          .fold<int>(0, (sum, s) => sum + s.seconds);
      days.add(DayBar(
        date: d,
        minutes: (mins / 60).round(),
        label: _shortDay(d.weekday),
      ));
    }

    final totalMinutes =
        days.fold<int>(0, (sum, d) => sum + d.minutes);
    final activeDays = days.where((d) => d.minutes > 0).length;
    final avg = totalMinutes / 7;

    DayBar? strongest;
    for (final d in days) {
      if (d.minutes > 0 &&
          (strongest == null || d.minutes > strongest.minutes)) {
        strongest = d;
      }
    }

    // Last-7-days subset for category stats.
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = sessions.where((s) => s.completedAt.isAfter(cutoff));

    final categoryMinutes = <ExerciseCategory, int>{};
    int sessionCount = 0;
    int sessionSeconds = 0;
    for (final s in recent) {
      categoryMinutes.update(s.category, (v) => v + s.seconds,
          ifAbsent: () => s.seconds);
      sessionCount += 1;
      sessionSeconds += s.seconds;
    }

    ExerciseCategory? topCategory;
    int topMinutes = 0;
    categoryMinutes.forEach((cat, sec) {
      if (sec > topMinutes) {
        topMinutes = sec;
        topCategory = cat;
      }
    });

    final triedCategories = categoryMinutes.keys.toSet();
    final missed = ExerciseCategory.values
        .where((c) => !triedCategories.contains(c))
        .toList();

    final avgSessionMinutes =
        sessionCount == 0 ? 0.0 : (sessionSeconds / sessionCount) / 60;

    int moodTracked = 0;
    int moodDeltaSum = 0;
    for (final s in recent) {
      final delta = s.moodDelta;
      if (delta != null) {
        moodTracked += 1;
        moodDeltaSum += delta;
      }
    }
    final avgMoodDelta =
        moodTracked == 0 ? null : moodDeltaSum / moodTracked;

    final bullets = _buildBullets(
      activeDays: activeDays,
      avg: avg,
      strongestDay: strongest,
      topCategory: topCategory,
      missed: missed,
      avgSessionMinutes: avgSessionMinutes,
      totalMinutes: totalMinutes,
      avgMoodDelta: avgMoodDelta,
      moodTrackedSessions: moodTracked,
    );

    return WeeklyInsights(
      last7Days: days,
      totalMinutes: totalMinutes,
      averagePerDay: avg,
      activeDays: activeDays,
      strongestDay: strongest,
      topCategory: topCategory,
      missedCategoriesThisWeek: missed,
      averageSessionMinutes: avgSessionMinutes,
      averageMoodDelta: avgMoodDelta,
      moodTrackedSessions: moodTracked,
      bullets: bullets,
    );
  }

  static List<String> _buildBullets({
    required int activeDays,
    required double avg,
    required DayBar? strongestDay,
    required ExerciseCategory? topCategory,
    required List<ExerciseCategory> missed,
    required double avgSessionMinutes,
    required int totalMinutes,
    required double? avgMoodDelta,
    required int moodTrackedSessions,
  }) {
    final out = <String>[];
    if (totalMinutes == 0) {
      out.add(
          'No sessions this week yet — even 2 minutes makes a great start.');
      return out;
    }
    out.add('You moved on $activeDays of 7 days '
        '(${avg.toStringAsFixed(1)} min/day on average).');
    if (strongestDay != null) {
      out.add('Strongest day: ${_longDay(strongestDay.date.weekday)} '
          '— ${strongestDay.minutes} min.');
    }
    if (topCategory != null) {
      out.add('Most-used category: ${topCategory.label.toLowerCase()}.');
    }
    if (missed.length == 1) {
      out.add(
          'You haven\'t done any ${missed.first.label.toLowerCase()} this week — '
          'a quick session would round things out.');
    } else if (missed.length >= 2 && missed.length < 4) {
      final names = missed
          .map((c) => c.label.toLowerCase())
          .join(', ');
      out.add('Missed this week: $names. Mix it up tomorrow.');
    }
    if (avgSessionMinutes > 0) {
      out.add('Average session length: '
          '${avgSessionMinutes.toStringAsFixed(1)} min.');
    }
    if (avgMoodDelta != null && moodTrackedSessions > 0) {
      final sign = avgMoodDelta > 0 ? '+' : '';
      final mood = avgMoodDelta == 0
          ? 'Mood stayed steady around your sessions ($moodTrackedSessions tracked).'
          : 'Movement shifted your mood by '
              '$sign${avgMoodDelta.toStringAsFixed(1)} on average '
              '($moodTrackedSessions sessions tracked).';
      out.add(mood);
    }
    return out;
  }

  static String _shortDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  static String _longDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }
}
