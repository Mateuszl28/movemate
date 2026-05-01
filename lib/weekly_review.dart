import 'package:flutter/material.dart';

import 'achievements.dart';
import 'models.dart';
import 'storage.dart';

class WeeklyReviewSummary {
  final int totalMinutes;
  final int sessionCount;
  final int activeDays;
  final ExerciseCategory? topCategory;
  final String? bestDayLabel;
  final int bestDayMinutes;
  final double? avgMoodDelta;
  final int moodTrackedSessions;
  final int newAchievements;
  final int prevTotalMinutes;

  const WeeklyReviewSummary({
    required this.totalMinutes,
    required this.sessionCount,
    required this.activeDays,
    required this.topCategory,
    required this.bestDayLabel,
    required this.bestDayMinutes,
    required this.avgMoodDelta,
    required this.moodTrackedSessions,
    required this.newAchievements,
    required this.prevTotalMinutes,
  });

  bool get hasData => sessionCount > 0;

  factory WeeklyReviewSummary.compute(Storage storage, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final sessions = storage.sessions;

    // Last week = the 7 days ending yesterday (so we recap finished week).
    final endOfLastWeek = DateTime(clock.year, clock.month, clock.day);
    final startOfLastWeek =
        endOfLastWeek.subtract(const Duration(days: 7));
    final startOfPriorWeek =
        startOfLastWeek.subtract(const Duration(days: 7));

    final lastWeekSessions = sessions
        .where((s) =>
            !s.completedAt.isBefore(startOfLastWeek) &&
            s.completedAt.isBefore(endOfLastWeek))
        .toList();
    final priorWeekSessions = sessions
        .where((s) =>
            !s.completedAt.isBefore(startOfPriorWeek) &&
            s.completedAt.isBefore(startOfLastWeek))
        .toList();

    final totalSec =
        lastWeekSessions.fold<int>(0, (sum, s) => sum + s.seconds);
    final priorSec =
        priorWeekSessions.fold<int>(0, (sum, s) => sum + s.seconds);

    final daysSet = lastWeekSessions
        .map((s) =>
            '${s.completedAt.year}-${s.completedAt.month}-${s.completedAt.day}')
        .toSet();

    // Best day.
    String? bestDayLabel;
    int bestDayMinutes = 0;
    final perDay = <DateTime, int>{};
    for (final s in lastWeekSessions) {
      final d = DateTime(s.completedAt.year, s.completedAt.month,
          s.completedAt.day);
      perDay.update(d, (v) => v + s.seconds, ifAbsent: () => s.seconds);
    }
    perDay.forEach((d, sec) {
      final mins = (sec / 60).round();
      if (mins > bestDayMinutes) {
        bestDayMinutes = mins;
        bestDayLabel = _longDay(d.weekday);
      }
    });

    // Top category.
    final perCat = <ExerciseCategory, int>{};
    for (final s in lastWeekSessions) {
      perCat.update(s.category, (v) => v + s.seconds,
          ifAbsent: () => s.seconds);
    }
    ExerciseCategory? topCat;
    int topSec = 0;
    perCat.forEach((c, sec) {
      if (sec > topSec) {
        topSec = sec;
        topCat = c;
      }
    });

    // Mood.
    int moodTracked = 0;
    int moodSum = 0;
    for (final s in lastWeekSessions) {
      final delta = s.moodDelta;
      if (delta != null) {
        moodTracked += 1;
        moodSum += delta;
      }
    }
    final avgMood =
        moodTracked == 0 ? null : moodSum / moodTracked;

    // New achievements (earned this week).
    final earnedAll = AchievementCatalog.earned(
            sessions, storage.currentStreak, storage.dailyGoalMinutes)
        .toSet();
    final earnedBefore = AchievementCatalog.earned(
            priorWeekSessions +
                sessions
                    .where((s) =>
                        s.completedAt.isBefore(startOfLastWeek))
                    .toList(),
            // approximate: streak before last week unknowable cheaply
            0,
            storage.dailyGoalMinutes)
        .toSet();
    final newAchievements =
        earnedAll.difference(earnedBefore).length;

    return WeeklyReviewSummary(
      totalMinutes: (totalSec / 60).round(),
      sessionCount: lastWeekSessions.length,
      activeDays: daysSet.length,
      topCategory: topCat,
      bestDayLabel: bestDayLabel,
      bestDayMinutes: bestDayMinutes,
      avgMoodDelta: avgMood,
      moodTrackedSessions: moodTracked,
      newAchievements: newAchievements,
      prevTotalMinutes: (priorSec / 60).round(),
    );
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

Future<void> maybeShowWeeklyReview(
  BuildContext context,
  Storage storage, {
  DateTime? now,
}) async {
  final clock = now ?? DateTime.now();
  // Show on Monday and only once per week.
  if (clock.weekday != DateTime.monday) return;
  final lastShownIso = storage.lastWeeklyReviewIso;
  if (lastShownIso != null) {
    final last = DateTime.tryParse(lastShownIso);
    if (last != null) {
      final diff = clock.difference(last).inDays;
      if (diff < 6) return;
    }
  }
  final summary = WeeklyReviewSummary.compute(storage, now: clock);
  if (!summary.hasData) {
    // Still mark it shown so we don't try every Monday.
    await storage.setLastWeeklyReviewIso(clock.toIso8601String());
    return;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => WeeklyReviewDialog(summary: summary),
  );
  await storage.setLastWeeklyReviewIso(clock.toIso8601String());
}

class WeeklyReviewDialog extends StatelessWidget {
  final WeeklyReviewSummary summary;
  const WeeklyReviewDialog({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final delta = summary.totalMinutes - summary.prevTotalMinutes;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 640),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('LAST WEEK',
                      style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          fontSize: 11)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Your week in MoveMate',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900, height: 1.1)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _BigStatCard(
                    label: 'Total movement',
                    value: '${summary.totalMinutes}',
                    unit: 'min',
                    sub: delta == 0
                        ? 'Same as the week before'
                        : delta > 0
                            ? '+$delta min vs the prior week'
                            : '$delta min vs the prior week',
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Sessions',
                          value: '${summary.sessionCount}',
                          color: const Color(0xFF7BC67E),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          label: 'Active days',
                          value: '${summary.activeDays} / 7',
                          color: const Color(0xFFFFB74D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (summary.bestDayLabel != null)
                    _Bullet(
                        emoji: '🏆',
                        text:
                            'Best day: **${summary.bestDayLabel}** with ${summary.bestDayMinutes} min'),
                  if (summary.topCategory != null)
                    _Bullet(
                        emoji: '🎯',
                        text:
                            'Most-used category: **${summary.topCategory!.label.toLowerCase()}**'),
                  if (summary.avgMoodDelta != null)
                    _Bullet(
                        emoji: '😊',
                        text: summary.avgMoodDelta! >= 0
                            ? 'Movement lifted your mood by **+${summary.avgMoodDelta!.toStringAsFixed(1)}** on average'
                            : 'Mood shifted **${summary.avgMoodDelta!.toStringAsFixed(1)}** — try a calmer category next week'),
                  if (summary.newAchievements > 0)
                    _Bullet(
                        emoji: '🎉',
                        text: summary.newAchievements == 1
                            ? '**1 new achievement** unlocked'
                            : '**${summary.newAchievements} new achievements** unlocked'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Onward!',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String sub;
  final Color color;
  const _BigStatCard(
      {required this.label,
      required this.value,
      required this.unit,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  )),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(unit,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  )),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String emoji;
  final String text;
  const _Bullet({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 8),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: _RichTextWithBold(
              text: text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _RichTextWithBold extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const _RichTextWithBold({required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(TextSpan(
        text: parts[i],
        style: isBold
            ? style?.copyWith(fontWeight: FontWeight.w800) ??
                const TextStyle(fontWeight: FontWeight.w800)
            : style,
      ));
    }
    return Text.rich(TextSpan(children: spans));
  }
}
