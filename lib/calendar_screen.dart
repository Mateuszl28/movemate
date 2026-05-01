import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'storage.dart';

class CalendarScreen extends StatefulWidget {
  final Storage storage;
  const CalendarScreen({super.key, required this.storage});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monthLabel = DateFormat('MMMM yyyy', 'en_US').format(_month);
    final sessions = widget.storage.sessions;
    final byDay = <String, List<SessionRecord>>{};
    for (final s in sessions) {
      final key = _key(s.completedAt);
      byDay.putIfAbsent(key, () => []).add(s);
    }
    final freezeDays = widget.storage.usedFreezeDates;

    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    // Monday-start grid leading offset.
    final leading = (firstOfMonth.weekday + 6) % 7;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;

    int monthlyMinutes = 0;
    int monthlyActive = 0;
    for (int i = 0; i < daysInMonth; i++) {
      final d = DateTime(_month.year, _month.month, i + 1);
      final list = byDay[_key(d)];
      if (list != null) {
        monthlyActive += 1;
        monthlyMinutes += list.fold<int>(0, (sum, s) => sum + s.seconds);
      }
    }
    monthlyMinutes = (monthlyMinutes / 60).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _month = DateTime(_month.year, _month.month - 1);
                        });
                      },
                    ),
                    Expanded(
                      child: Text(monthLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        final now = DateTime.now();
                        final next =
                            DateTime(_month.year, _month.month + 1);
                        // Don't go past current month.
                        if (next.isBefore(DateTime(now.year, now.month + 1))) {
                          setState(() => _month = next);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final wd in const [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun'
                    ])
                      Expanded(
                        child: Center(
                          child: Text(wd,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCells,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemBuilder: (_, i) {
                    final dayIndex = i - leading;
                    if (dayIndex < 0 || dayIndex >= daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    final d = DateTime(
                        _month.year, _month.month, dayIndex + 1);
                    final key = _key(d);
                    final list = byDay[key];
                    final freeze = freezeDays.contains(key);
                    final isToday = _isToday(d);
                    final cats = (list ?? [])
                        .map((s) => s.category)
                        .toSet()
                        .toList();
                    return _CalendarDayCell(
                      date: d,
                      sessions: list ?? const [],
                      categories: cats,
                      isToday: isToday,
                      isFreeze: freeze,
                      onTap: list != null && list.isNotEmpty
                          ? () => _showDayDetails(context, d, list)
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MonthStat(
                    label: 'Active days',
                    value: '$monthlyActive',
                    color: scheme.primary,
                  ),
                ),
                Container(
                    width: 1, height: 32, color: scheme.outlineVariant),
                Expanded(
                  child: _MonthStat(
                    label: 'Total minutes',
                    value: '$monthlyMinutes',
                    color: scheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final cat in ExerciseCategory.values)
                  _LegendDot(label: cat.label, color: cat.accent),
                _LegendDot(
                    label: 'Streak freeze', color: const Color(0xFF64B5F6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDayDetails(
      BuildContext context, DateTime date, List<SessionRecord> sessions) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('EEEE, d MMM', 'en_US');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final totalSec =
            sessions.fold<int>(0, (sum, s) => sum + s.seconds);
        final totalMin = (totalSec / 60).round();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(fmt.format(date),
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                  '$totalMin min · ${sessions.length} session${sessions.length == 1 ? "" : "s"}',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _DaySessionTile(session: sessions[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final List<SessionRecord> sessions;
  final List<ExerciseCategory> categories;
  final bool isToday;
  final bool isFreeze;
  final VoidCallback? onTap;
  const _CalendarDayCell({
    required this.date,
    required this.sessions,
    required this.categories,
    required this.isToday,
    required this.isFreeze,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSessions = sessions.isNotEmpty;
    final bg = hasSessions
        ? scheme.primary.withValues(alpha: 0.08)
        : Colors.transparent;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: scheme.primary, width: 1.6)
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isToday ? FontWeight.w900 : FontWeight.w600,
                    color: isToday
                        ? scheme.primary
                        : hasSessions
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 3),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFreeze && !hasSessions)
                      const _Dot(color: Color(0xFF64B5F6))
                    else
                      for (final c in categories.take(4))
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 1),
                          child: _Dot(color: c.accent),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DaySessionTile extends StatelessWidget {
  final SessionRecord session;
  const _DaySessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = session.category.accent;
    final fmt = DateFormat.Hm();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(session.category.icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(session.planTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    Text(fmt.format(session.completedAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
                Text(
                    '${(session.seconds / 60).round()} min · ${session.category.label}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant)),
                if (session.note != null && session.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 6, top: 1),
                            child: Text('📝',
                                style: TextStyle(fontSize: 13)),
                          ),
                          Expanded(
                            child: Text(session.note!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      height: 1.3,
                                    )),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (session.moodDelta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      session.moodDelta! > 0
                          ? 'Mood +${session.moodDelta!} ✨'
                          : session.moodDelta == 0
                              ? 'Mood steady 🌿'
                              : 'Mood ${session.moodDelta} 💭',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w800),
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

class _MonthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MonthStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color, fontWeight: FontWeight.w900)),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
