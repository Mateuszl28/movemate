import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'achievements.dart';
import 'models.dart';
import 'storage.dart';

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
    final earned = AchievementCatalog.earned(
      sessions,
      streak,
      storage.dailyGoalMinutes,
    ).map((a) => a.id).toSet();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Progress',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
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
            Text('Activity (28 days)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _Heatmap(data: mapData),
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
            childAspectRatio: 0.78,
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
        padding: const EdgeInsets.all(8),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: earned ? 1.0 : 0.35,
              child: Text(achievement.emoji,
                  style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: earned
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          RichText(
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(fmt.format(session.completedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant)),
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
