import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'adaptive_plan.dart';
import 'models.dart';
import 'session_screen.dart';
import 'storage.dart';
import 'transitions.dart';

/// Renders the 7-day adaptive plan as a vertical list. Tapping a day starts
/// the session for that day. Today is highlighted.
class WeeklyPlanScreen extends StatelessWidget {
  final Storage storage;
  const WeeklyPlanScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final plan = AdaptivePlan.build(storage);
    final today = DateTime.now();
    final todayKey = _dayKey(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your week'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Text('🗓️', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Adaptive 7-day plan',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.1)),
                        const SizedBox(height: 4),
                        Text(
                          'Built from your profile, body coverage, pain journal, sleep, and energy.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Colors.white70, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < plan.days.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DayCard(
                  day: plan.days[i],
                  isToday: _dayKey(plan.days[i].date) == todayKey,
                  onStart: () => _start(context, plan.days[i].plan),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, WorkoutPlan plan) async {
    await Navigator.of(context).push<bool>(
      FadeThroughRoute(
        builder: (_) => SessionScreen(plan: plan, storage: storage),
      ),
    );
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month}-${d.day}';
}

class _DayCard extends StatelessWidget {
  final AdaptiveDay day;
  final bool isToday;
  final VoidCallback onStart;
  const _DayCard({
    required this.day,
    required this.isToday,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = day.plan.primaryCategory.accent;
    final weekday = DateFormat('EEE', 'en_US').format(day.date);
    final dateNum = DateFormat('d').format(day.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onStart,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: isToday
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isToday
                  ? scheme.primary
                  : accent.withValues(alpha: 0.35),
              width: isToday ? 1.6 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(weekday.toUpperCase(),
                        style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                    Text(dateNum,
                        style: TextStyle(
                            color: accent,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.05)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(day.plan.primaryCategory.icon,
                            size: 14, color: accent),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(day.theme,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12)),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('TODAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                )),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(day.plan.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(day.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                            height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(day.plan.formattedDuration,
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
