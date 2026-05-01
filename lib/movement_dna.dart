import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

class MovementDna {
  final Map<ExerciseCategory, double> distribution;
  final int totalMinutes;
  final ExerciseCategory dominant;
  final ExerciseCategory neglected;
  final String archetype;
  final String archetypeEmoji;
  final String archetypeBlurb;

  MovementDna({
    required this.distribution,
    required this.totalMinutes,
    required this.dominant,
    required this.neglected,
    required this.archetype,
    required this.archetypeEmoji,
    required this.archetypeBlurb,
  });

  bool get hasData => totalMinutes > 0;

  static MovementDna compute(
    List<SessionRecord> sessions, {
    DateTime? now,
    int days = 30,
  }) {
    final cutoff = (now ?? DateTime.now()).subtract(Duration(days: days));
    final totals = <ExerciseCategory, int>{
      for (final c in ExerciseCategory.values) c: 0,
    };
    int totalSec = 0;
    for (final s in sessions) {
      if (s.completedAt.isBefore(cutoff)) continue;
      totals[s.category] = (totals[s.category] ?? 0) + s.seconds;
      totalSec += s.seconds;
    }

    final distribution = <ExerciseCategory, double>{};
    for (final entry in totals.entries) {
      distribution[entry.key] =
          totalSec == 0 ? 0.0 : entry.value / totalSec;
    }

    var dominant = ExerciseCategory.stretch;
    var neglected = ExerciseCategory.stretch;
    var maxV = -1.0;
    var minV = 2.0;
    for (final entry in distribution.entries) {
      if (entry.value > maxV) {
        maxV = entry.value;
        dominant = entry.key;
      }
      if (entry.value < minV) {
        minV = entry.value;
        neglected = entry.key;
      }
    }

    final values = distribution.values.toList();
    final spread = values.isEmpty
        ? 0.0
        : (values.reduce(max) - values.reduce(min));

    String archetype;
    String emoji;
    String blurb;
    if (totalSec == 0) {
      archetype = 'Blank slate';
      emoji = '🌱';
      blurb = 'Do your first session — your DNA fills in fast.';
    } else if (maxV > 0.55) {
      switch (dominant) {
        case ExerciseCategory.stretch:
          archetype = 'The Stretcher';
          emoji = '🤸';
          blurb = 'You love to lengthen. Sprinkle in cardio to round it out.';
          break;
        case ExerciseCategory.mobility:
          archetype = 'The Mover';
          emoji = '🦴';
          blurb = 'Mobility-first. Add breath work for nervous-system reset.';
          break;
        case ExerciseCategory.breath:
          archetype = 'The Breather';
          emoji = '🫁';
          blurb = 'Calm, anchored. Throw in mobility to keep joints happy.';
          break;
        case ExerciseCategory.cardio:
          archetype = 'The Athlete';
          emoji = '🏃';
          blurb = 'High output. Stretch days will protect your joints.';
          break;
      }
    } else if (spread < 0.18) {
      archetype = 'The All-rounder';
      emoji = '🧬';
      blurb = 'Balanced across all four. Keep the rhythm.';
    } else {
      archetype = 'The Explorer';
      emoji = '🧭';
      blurb = 'You mix it up. Try doubling down on $neglected next week.';
    }

    return MovementDna(
      distribution: distribution,
      totalMinutes: totalSec ~/ 60,
      dominant: dominant,
      neglected: neglected,
      archetype: archetype,
      archetypeEmoji: emoji,
      archetypeBlurb: blurb,
    );
  }
}

class MovementDnaCard extends StatelessWidget {
  final MovementDna dna;
  const MovementDnaCard({super.key, required this.dna});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Movement DNA',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('30 days',
                    style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('How your last 30 days are split.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.0,
            child: _RadarStack(dna: dna),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(dna.archetypeEmoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(dna.archetype,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: scheme.onSurface)),
                      Text(dna.archetypeBlurb,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.3)),
                    ],
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

class _RadarStack extends StatelessWidget {
  final MovementDna dna;
  const _RadarStack({required this.dna});

  static const _order = [
    ExerciseCategory.stretch, // top
    ExerciseCategory.mobility, // right
    ExerciseCategory.cardio, // bottom
    ExerciseCategory.breath, // left
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final values = _order
        .map((c) => dna.distribution[c] ?? 0.0)
        .toList(growable: false);
    final accents = _order.map((c) => c.accent).toList(growable: false);

    return LayoutBuilder(builder: (ctx, constraints) {
      final size = constraints.biggest.shortestSide;
      final radius = size / 2 * 0.78;
      final center = Offset(size / 2, size / 2);
      Offset offsetFor(int i, double r) {
        final angle = -pi / 2 + i * pi / 2;
        return Offset(
          center.dx + cos(angle) * r,
          center.dy + sin(angle) * r,
        );
      }

      Widget label(int i) {
        final cat = _order[i];
        final v = values[i];
        final pct = (v * 100).round();
        final pos = offsetFor(i, radius + 26);
        const w = 70.0;
        const h = 36.0;
        return Positioned(
          left: pos.dx - w / 2,
          top: pos.dy - h / 2,
          width: w,
          height: h,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 12, color: cat.accent),
                    const SizedBox(width: 4),
                    Text('$pct%',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface)),
                  ],
                ),
                Text(cat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        );
      }

      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DnaRadarPainter(
                values: values,
                accents: accents,
                gridColor: scheme.outline.withValues(alpha: 0.25),
                fillColor: scheme.primary.withValues(alpha: 0.18),
                strokeColor: scheme.primary,
              ),
            ),
          ),
          for (int i = 0; i < _order.length; i++) label(i),
        ],
      );
    });
  }
}

class _DnaRadarPainter extends CustomPainter {
  final List<double> values;
  final List<Color> accents;
  final Color gridColor;
  final Color fillColor;
  final Color strokeColor;

  _DnaRadarPainter({
    required this.values,
    required this.accents,
    required this.gridColor,
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 * 0.78;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    Offset point(int i, double r) {
      final angle = -pi / 2 + i * pi / 2;
      return Offset(
        center.dx + cos(angle) * r,
        center.dy + sin(angle) * r,
      );
    }

    for (final factor in const [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (int i = 0; i < 4; i++) {
        final p = point(i, radius * factor);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < 4; i++) {
      canvas.drawLine(center, point(i, radius), gridPaint);
    }

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final hasAny = values.any((v) => v > 0);
    if (hasAny) {
      final valuePath = Path();
      for (int i = 0; i < 4; i++) {
        final v = values[i].clamp(0.0, 1.0);
        final p = point(i, radius * v);
        if (i == 0) {
          valuePath.moveTo(p.dx, p.dy);
        } else {
          valuePath.lineTo(p.dx, p.dy);
        }
      }
      valuePath.close();
      canvas.drawPath(valuePath, fillPaint);
      canvas.drawPath(valuePath, strokePaint);

      for (int i = 0; i < 4; i++) {
        final v = values[i].clamp(0.0, 1.0);
        final p = point(i, radius * v);
        canvas.drawCircle(p, 5.5, Paint()..color = accents[i]);
        canvas.drawCircle(
          p,
          5.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DnaRadarPainter old) {
    for (int i = 0; i < values.length; i++) {
      if (old.values[i] != values[i]) return true;
    }
    return false;
  }
}
