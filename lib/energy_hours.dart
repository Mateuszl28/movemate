import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';

class EnergyHours {
  final List<int> minutesPerHour; // length 24
  final int peakHour;
  final int peakMinutes;
  final int totalMinutes;

  EnergyHours({
    required this.minutesPerHour,
    required this.peakHour,
    required this.peakMinutes,
    required this.totalMinutes,
  });

  bool get hasData => totalMinutes > 0;

  static EnergyHours from(
    List<SessionRecord> sessions, {
    DateTime? now,
    int days = 30,
  }) {
    final cutoff = (now ?? DateTime.now()).subtract(Duration(days: days));
    final buckets = List<int>.filled(24, 0);
    int total = 0;
    for (final s in sessions) {
      if (s.completedAt.isBefore(cutoff)) continue;
      final m = (s.seconds / 60).round();
      buckets[s.completedAt.hour] += m;
      total += m;
    }
    int peakHour = 0;
    int peakV = -1;
    for (int i = 0; i < 24; i++) {
      if (buckets[i] > peakV) {
        peakV = buckets[i];
        peakHour = i;
      }
    }
    return EnergyHours(
      minutesPerHour: buckets,
      peakHour: peakHour,
      peakMinutes: peakV.clamp(0, 1 << 31),
      totalMinutes: total,
    );
  }
}

class EnergyHoursCard extends StatelessWidget {
  final EnergyHours data;
  const EnergyHoursCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Energy hours',
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
          Text(
              data.hasData
                  ? 'Peak ${_fmtHour(data.peakHour)} · ${data.peakMinutes} min there.'
                  : 'Move a few times — your peak hour will appear here.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.0,
            child: CustomPaint(
              painter: _ClockPainter(
                buckets: data.minutesPerHour,
                peakHour: data.peakHour,
                peakValue: data.peakMinutes,
                accent: scheme.primary,
                gridColor: scheme.outline.withValues(alpha: 0.25),
                textColor: scheme.onSurfaceVariant,
                hubColor: scheme.surfaceContainerHighest,
                hubBorder: scheme.outline.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendDot(color: scheme.primary, label: 'High'),
              _LegendDot(
                  color: scheme.primary.withValues(alpha: 0.45),
                  label: 'Med'),
              _LegendDot(
                  color: scheme.primary.withValues(alpha: 0.18),
                  label: 'Low'),
              _LegendDot(
                  color: scheme.outline.withValues(alpha: 0.25),
                  label: 'None'),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtHour(int h) {
    final hh = h.toString().padLeft(2, '0');
    return '$hh:00';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ClockPainter extends CustomPainter {
  final List<int> buckets;
  final int peakHour;
  final int peakValue;
  final Color accent;
  final Color gridColor;
  final Color textColor;
  final Color hubColor;
  final Color hubBorder;

  _ClockPainter({
    required this.buckets,
    required this.peakHour,
    required this.peakValue,
    required this.accent,
    required this.gridColor,
    required this.textColor,
    required this.hubColor,
    required this.hubBorder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.shortestSide / 2 * 0.92;
    final innerR = outerR * 0.42;
    final gap = (2 * pi / 24) * 0.18;
    final segArc = (2 * pi / 24) - gap;

    for (int i = 0; i < 24; i++) {
      final v = buckets[i];
      double alpha;
      if (peakValue == 0) {
        alpha = 0.0;
      } else {
        alpha = v / peakValue;
      }
      final Color color;
      if (v == 0) {
        color = gridColor;
      } else if (alpha > 0.66) {
        color = accent;
      } else if (alpha > 0.33) {
        color = accent.withValues(alpha: 0.55);
      } else {
        color = accent.withValues(alpha: 0.28);
      }
      final start = -pi / 2 + i * (2 * pi / 24) + gap / 2;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerR - innerR
        ..strokeCap = StrokeCap.butt;
      final midR = (outerR + innerR) / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: midR),
        start,
        segArc,
        false,
        paint,
      );
    }

    final hubPaint = Paint()
      ..color = hubColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerR - 4, hubPaint);
    final hubStroke = Paint()
      ..color = hubBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, innerR - 4, hubStroke);

    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    final hourText = peakValue == 0
        ? '—'
        : '${peakHour.toString().padLeft(2, '0')}:00';
    tp.text = TextSpan(
      text: hourText,
      style: TextStyle(
        color: accent,
        fontWeight: FontWeight.w900,
        fontSize: innerR * 0.55,
      ),
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(
        center.dx - tp.width / 2,
        center.dy - tp.height / 2 - 6,
      ),
    );

    tp.text = TextSpan(
      text: peakValue == 0 ? 'no peak yet' : 'peak hour',
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w700,
        fontSize: innerR * 0.22,
      ),
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(
        center.dx - tp.width / 2,
        center.dy + innerR * 0.12,
      ),
    );

    for (final h in const [0, 6, 12, 18]) {
      final angle = -pi / 2 + h * (2 * pi / 24);
      final pos = Offset(
        center.dx + cos(angle) * (outerR + 14),
        center.dy + sin(angle) * (outerR + 14),
      );
      tp.text = TextSpan(
        text: '$h',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) {
    if (old.peakHour != peakHour || old.peakValue != peakValue) return true;
    for (int i = 0; i < buckets.length; i++) {
      if (old.buckets[i] != buckets[i]) return true;
    }
    return false;
  }
}
