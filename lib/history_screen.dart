import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'achievements.dart';
import 'body_coverage.dart';
import 'calendar_screen.dart';
import 'consistency_heatmap.dart';
import 'energy_hours.dart';
import 'insights.dart';
import 'models.dart';
import 'movement_dna.dart';
import 'records.dart';
import 'storage.dart';
import 'transitions.dart';

class HistoryScreen extends StatelessWidget {
  final Storage storage;
  const HistoryScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final sessions = storage.sessions;
    final week = storage.weekMinutes;
    final today = storage.todayMinutes;
    final streak = storage.currentStreak;
    final mapData = storage.minutesByDay(days: 28);
    final heatmapData = storage.minutesByDay(days: 91);
    final earned = AchievementCatalog.earned(
      sessions,
      streak,
      storage.dailyGoalMinutes,
      eyeBreaksToday: storage.eyeBreaksToday,
      eyeBreaksWeek: storage.eyeBreaksWeek,
      bestPostureScore: storage.bestPostureScore,
      ranPostureCheck: storage.hasRunPostureCheck,
      sleepEntriesWeek: storage.sleepEntriesInLastDays(),
      mindfulWeek: storage.mindfulWeek,
      hasMindfulMoment: storage.hasAnyMindfulMoment,
    ).map((a) => a.id).toSet();
    final insights = WeeklyInsights.from(sessions);
    final coverage = BodyCoverage.lastWeek(sessions, DateTime.now());
    final dna = MovementDna.compute(sessions);
    final energy = EnergyHours.from(sessions);
    final hydrationByDay = storage.hydrationByDay(days: 7);
    final hydrationGoal = storage.hydrationGoalGlasses;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Progress',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.calendar_month),
                  tooltip: 'Open calendar',
                  onPressed: () {
                    Navigator.of(context).push(FadeThroughRoute(
                      builder: (_) => CalendarScreen(storage: storage),
                    ));
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('See how consistent your movement is over time.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'Today',
                        value: '$today',
                        unit: 'min',
                        icon: Icons.today,
                        color: const Color(0xFF7BC67E))),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        label: 'Week',
                        value: '$week',
                        unit: 'min',
                        icon: Icons.calendar_view_week,
                        color: const Color(0xFF64B5F6))),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        label: 'Streak',
                        value: '$streak',
                        unit: streak == 1 ? 'day' : 'days',
                        icon: Icons.local_fire_department,
                        color: const Color(0xFFFFB74D))),
              ],
            ),
            const SizedBox(height: 24),
            Text('This week',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _WeeklyBarChart(insights: insights, goal: storage.dailyGoalMinutes),
            const SizedBox(height: 12),
            _MoodTrendCard(sessions: sessions),
            const SizedBox(height: 12),
            _InsightsCard(bullets: insights.bullets),
            const SizedBox(height: 24),
            ConsistencyHeatmap(
              minutesByDay: heatmapData,
              dailyGoal: storage.dailyGoalMinutes,
            ),
            const SizedBox(height: 18),
            Text('Activity (28 days)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _Heatmap(data: mapData),
            const SizedBox(height: 24),
            MovementDnaCard(dna: dna),
            const SizedBox(height: 24),
            EnergyHoursCard(data: energy),
            const SizedBox(height: 24),
            _BodyCoverageSection(coverage: coverage),
            const SizedBox(height: 24),
            _HydrationSection(byDay: hydrationByDay, goal: hydrationGoal),
            const SizedBox(height: 24),
            _PersonalRecordsSection(
                records: PersonalRecords.from(sessions)),
            const SizedBox(height: 24),
            _AchievementsSection(earnedIds: earned),
            const SizedBox(height: 24),
            Text('Recent sessions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No sessions yet. Start your first one — just 2 minutes is enough!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...sessions.take(15).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _SessionTile(session: s),
                  )),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final WeeklyInsights insights;
  final int goal;
  const _WeeklyBarChart({required this.insights, required this.goal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxMin = insights.last7Days
        .fold<int>(goal, (m, d) => d.minutes > m ? d.minutes : m)
        .clamp(1, 9999);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${insights.totalMinutes}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('min total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Goal $goal min/day',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in insights.last7Days)
                  Expanded(
                    child: _BarColumn(
                      bar: d,
                      maxMin: maxMin,
                      goal: goal,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final DayBar bar;
  final int maxMin;
  final int goal;
  const _BarColumn(
      {required this.bar, required this.maxMin, required this.goal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = (bar.minutes / maxMin).clamp(0.0, 1.0);
    final hitGoal = bar.minutes >= goal && goal > 0;
    final isToday = _isToday(bar.date);
    final color = bar.minutes == 0
        ? scheme.surfaceContainerHighest
        : (hitGoal ? scheme.primary : scheme.primary.withValues(alpha: 0.55));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (bar.minutes > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${bar.minutes}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800)),
            ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: ratio),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, val, _) => Container(
              height: 110 * val + 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                  bottom: Radius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(bar.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isToday ? scheme.primary : scheme.onSurfaceVariant,
                    fontWeight:
                        isToday ? FontWeight.w800 : FontWeight.w600,
                  )),
        ],
      ),
    );
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _MoodTrendCard extends StatelessWidget {
  final List<SessionRecord> sessions;
  const _MoodTrendCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final tracked = sessions
        .where((s) => s.moodDelta != null)
        .toList()
        .reversed // sessions are newest-first; reverse to chronological
        .toList();
    final last = tracked.length > 12
        ? tracked.sublist(tracked.length - 12)
        : tracked;
    final scheme = Theme.of(context).colorScheme;

    if (last.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Text('😊', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Track mood before/after a session to see how movement shifts how you feel.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mood, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Mood trend',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${last.length} session${last.length == 1 ? "" : "s"}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (final s in last)
                  Expanded(
                    child: _MoodBar(delta: s.moodDelta!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Older',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              Text('Latest',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodBar extends StatelessWidget {
  final int delta;
  const _MoodBar({required this.delta});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final positive = delta > 0;
    final neutral = delta == 0;
    final color = positive
        ? const Color(0xFF2EB872)
        : neutral
            ? scheme.onSurfaceVariant.withValues(alpha: 0.55)
            : const Color(0xFFE57373);
    // Bar height represents |delta| in 0..4 range from a 30px center axis.
    final magnitude = delta.abs().clamp(0, 4);
    final h = magnitude == 0 ? 6.0 : 8.0 + magnitude * 7.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: positive
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: h),
                      duration: const Duration(milliseconds: 500),
                      builder: (_, val, _) => Container(
                        height: val,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: scheme.outlineVariant,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: !positive && !neutral
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: h),
                      duration: const Duration(milliseconds: 500),
                      builder: (_, val, _) => Container(
                        height: val,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(6)),
                        ),
                      ),
                    )
                  : neutral
                      ? Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final List<String> bullets;
  const _InsightsCard({required this.bullets});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text('Insights',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(b,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurface, height: 1.35)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BodyCoverageSection extends StatelessWidget {
  final BodyCoverage coverage;
  const _BodyCoverageSection({required this.coverage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = coverage.secondsByArea.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxSec = entries.isEmpty
        ? 60
        : entries.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Body coverage',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Text('· last 7 days',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: entries.isEmpty
              ? Row(
                  children: [
                    const Text('🫥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          'No coverage logged yet — your first session will start the map.',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in entries.take(8))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BodyAreaBar(
                          area: e.key,
                          minutes: ((e.value) / 60).round(),
                          ratio: (e.value / maxSec).clamp(0.0, 1.0),
                        ),
                      ),
                    if (coverage.neglected.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined,
                                size: 16, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Untouched: ${coverage.neglected.take(4).map((a) => a.label.toLowerCase()).join(", ")}.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _BodyAreaBar extends StatelessWidget {
  final BodyArea area;
  final int minutes;
  final double ratio;
  const _BodyAreaBar({
    required this.area,
    required this.minutes,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Row(
            children: [
              Text(area.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(area.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: ratio),
              duration: const Duration(milliseconds: 700),
              builder: (_, val, _) => LinearProgressIndicator(
                value: val,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          child: Text('$minutes min',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface)),
        ),
      ],
    );
  }
}

class _PersonalRecordsSection extends StatelessWidget {
  final List<PersonalRecord> records;
  const _PersonalRecordsSection({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal records',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.85,
            children: [
              for (final r in records) _RecordTile(record: r),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final PersonalRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(record.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(record.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6)),
                Text(record.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.15)),
                if (record.hint != null)
                  Text(record.hint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final Set<String> earnedIds;
  const _AchievementsSection({required this.earnedIds});

  @override
  Widget build(BuildContext context) {
    final items = AchievementCatalog.all;
    final earnedCount = earnedIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Achievements',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text('$earnedCount / ${items.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.92,
            children: [
              for (final a in items)
                _BadgeTile(
                    achievement: a, earned: earnedIds.contains(a.id)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement achievement;
  final bool earned;
  const _BadgeTile({required this.achievement, required this.earned});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '${achievement.name}\n${achievement.description}',
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: earned
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: earned ? scheme.primary : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: earned ? 1.0 : 0.35,
              child: Text(achievement.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                achievement.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: earned
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  final Map<String, int> data;
  const _Heatmap({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxMin = entries.fold<int>(
        1, (m, e) => e.value > m ? e.value : m);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        children: [
          for (final entry in entries)
            _HeatmapCell(intensity: entry.value / maxMin, minutes: entry.value),
        ],
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final double intensity;
  final int minutes;
  const _HeatmapCell({required this.intensity, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.primary;
    final color = minutes == 0
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Color.lerp(base.withValues(alpha: 0.18), base, intensity.clamp(0.2, 1.0))!;
    return Tooltip(
      message: minutes == 0 ? 'No activity' : '$minutes min',
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionRecord session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final accent = session.category.accent;
    final fmt = DateFormat('d MMM, HH:mm', 'en_US');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(session.category.icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.planTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(fmt.format(session.completedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
                if (session.note != null && session.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1, right: 4),
                          child: Text('📝',
                              style: TextStyle(fontSize: 12)),
                        ),
                        Expanded(
                          child: Text(session.note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontStyle: FontStyle.italic,
                                      height: 1.3)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Text('${(session.seconds / 60).round()} min',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _HydrationSection extends StatelessWidget {
  final Map<String, int> byDay;
  final int goal;
  const _HydrationSection({required this.byDay, required this.goal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const blue = Color(0xFF1E88E5);
    final entries = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final values = entries.map((e) => e.value).toList();
    final maxV = (values.isEmpty ? goal : values.reduce((a, b) => a > b ? a : b))
        .clamp(goal, 9999);
    final total = values.fold<int>(0, (a, b) => a + b);
    final daysHit = values.where((v) => v >= goal).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💧', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('Hydration · 7 days',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$daysHit/7 days hit',
                    style: const TextStyle(
                        color: blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$total glasses logged in the last week.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < entries.length; i++)
                  Expanded(
                    child: _HydrationBar(
                      label: _shortDow(entries[i].key),
                      value: entries[i].value,
                      goal: goal,
                      maxV: maxV,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDow(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) return '';
    final d = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return labels[(d.weekday - 1) % 7];
  }
}

class _HydrationBar extends StatelessWidget {
  final String label;
  final int value;
  final int goal;
  final int maxV;
  const _HydrationBar({
    required this.label,
    required this.value,
    required this.goal,
    required this.maxV,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1E88E5);
    final scheme = Theme.of(context).colorScheme;
    final fill = maxV == 0 ? 0.0 : value / maxV;
    final hitGoal = value >= goal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fill.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 600),
              builder: (_, v, _) => Container(
                width: double.infinity,
                height: (60 * v).clamp(2.0, 60.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: hitGoal
                        ? [blue, const Color(0xFF64B5F6)]
                        : [
                            blue.withValues(alpha: 0.55),
                            blue.withValues(alpha: 0.35)
                          ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
