import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// GitHub-style activity grid: 13 weeks × 7 days, today in the bottom-right
/// corner. Each cell tints with daily minutes (0/light/medium/strong/peak).
class ConsistencyHeatmap extends StatelessWidget {
  /// Map keyed by 'YYYY-MM-DD' to minutes-on-that-day.
  final Map<String, int> minutesByDay;
  final int weeks;
  final int dailyGoal;
  const ConsistencyHeatmap({
    super.key,
    required this.minutesByDay,
    required this.dailyGoal,
    this.weeks = 13,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Anchor: bottom-right cell is today; columns go week by week.
    // Day-of-week index: Monday=0..Sunday=6.
    final dowToday = (today.weekday + 6) % 7;
    final totalCells = weeks * 7;
    // Date for cell (col, row) where col 0 = oldest week, col weeks-1 = current.
    DateTime dateAt(int col, int row) {
      final offsetFromTodayCell =
          (weeks - 1 - col) * 7 + (dowToday - row);
      return today.subtract(Duration(days: offsetFromTodayCell));
    }

    int activeDays = 0;
    int totalMinutes = 0;
    int longestStreak = 0;
    int curStreak = 0;
    final cellMins = List<int>.filled(totalCells, 0);
    int maxMin = 1;
    for (int col = 0; col < weeks; col++) {
      for (int row = 0; row < 7; row++) {
        final d = dateAt(col, row);
        if (d.isAfter(today)) continue;
        final key = _key(d);
        final m = minutesByDay[key] ?? 0;
        cellMins[col * 7 + row] = m;
        if (m > 0) {
          activeDays++;
          totalMinutes += m;
          curStreak++;
          if (curStreak > longestStreak) longestStreak = curStreak;
        } else {
          curStreak = 0;
        }
        if (m > maxMin) maxMin = m;
      }
    }

    final scale = (maxMin > dailyGoal ? maxMin : dailyGoal).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${weeks * 7}-day consistency',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '$activeDays active days · $totalMinutes min · best streak $longestStreak',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _legendSwatches(scheme),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final labelGap = 22.0;
              final available = constraints.maxWidth - labelGap;
              final spacing = 3.0;
              final cellSize =
                  (available - spacing * (weeks - 1)) / weeks;
              final clamped = cellSize.clamp(8.0, 24.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day-of-week labels.
                  SizedBox(
                    width: labelGap,
                    height: 7 * clamped + 6 * spacing,
                    child: Column(
                      children: [
                        for (int row = 0; row < 7; row++)
                          Expanded(
                            child: Center(
                              child: Text(
                                _shortDow(row),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: row.isOdd ? 1 : 0),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: spacing,
                      direction: Axis.horizontal,
                      children: [
                        for (int col = 0; col < weeks; col++)
                          SizedBox(
                            width: clamped,
                            child: Column(
                              children: [
                                for (int row = 0; row < 7; row++)
                                  _Cell(
                                    minutes: cellMins[col * 7 + row],
                                    date: dateAt(col, row),
                                    scale: scale,
                                    size: clamped,
                                    spacing: spacing,
                                    isToday:
                                        col == weeks - 1 && row == dowToday,
                                    color: scheme.primary,
                                    base: scheme.surfaceContainerHighest,
                                    today: today,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legendSwatches(ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('less',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant)),
        const SizedBox(width: 6),
        for (final a in const [0.10, 0.30, 0.55, 0.80, 1.0])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: a),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: 6),
        Text('more',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant)),
      ],
    );
  }

  String _shortDow(int row) {
    // Show every other label: Tue, Thu, Sat
    switch (row) {
      case 1:
        return 'Tue';
      case 3:
        return 'Thu';
      case 5:
        return 'Sat';
      default:
        return '';
    }
  }

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _Cell extends StatelessWidget {
  final int minutes;
  final DateTime date;
  final double scale;
  final double size;
  final double spacing;
  final bool isToday;
  final Color color;
  final Color base;
  final DateTime today;
  const _Cell({
    required this.minutes,
    required this.date,
    required this.scale,
    required this.size,
    required this.spacing,
    required this.isToday,
    required this.color,
    required this.base,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final isFuture = date.isAfter(today);
    final intensity = (minutes / scale).clamp(0.0, 1.0);
    final tint = minutes == 0
        ? base
        : color.withValues(alpha: 0.18 + 0.72 * intensity);
    final tooltip = isFuture
        ? '—'
        : '${DateFormat('MMM d').format(date)} · $minutes min';
    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isFuture ? Colors.transparent : tint,
            borderRadius: BorderRadius.circular(3),
            border: isToday
                ? Border.all(color: color, width: 1.4)
                : null,
          ),
        ),
      ),
    );
  }
}
