import 'dart:math';

import 'package:flutter/material.dart';

import 'body_coverage.dart';
import 'models.dart';

/// Hexagon radar visualizing per-area minutes worked over the last 7 days.
/// Uses a canonical 6-axis layout (neck/shoulders/back/core/hips/legs) so the
/// chart shape is comparable across users + weeks.
class BodyCoverageRadar extends StatelessWidget {
  final BodyCoverage coverage;
  static const _axes = <BodyArea>[
    BodyArea.neck,
    BodyArea.shoulders,
    BodyArea.back,
    BodyArea.core,
    BodyArea.hips,
    BodyArea.legs,
  ];

  const BodyCoverageRadar({super.key, required this.coverage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final values = _axes.map((a) => coverage.minutesFor(a)).toList();
    final maxVal = values.fold<int>(10, (m, v) => v > m ? v : m);
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _RadarPainter(
          axes: _axes,
          values: values,
          maxVal: maxVal,
          fill: scheme.primary,
          axis: scheme.outline.withValues(alpha: 0.30),
          axisStrong: scheme.outline.withValues(alpha: 0.55),
          label: scheme.onSurface,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<BodyArea> axes;
  final List<int> values;
  final int maxVal;
  final Color fill;
  final Color axis;
  final Color axisStrong;
  final Color label;

  _RadarPainter({
    required this.axes,
    required this.values,
    required this.maxVal,
    required this.fill,
    required this.axis,
    required this.axisStrong,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Reserve space for labels around the chart.
    final radius = size.shortestSide / 2 - 28;
    final n = axes.length;
    // Start at -pi/2 so the first axis points straight up.
    final angleOf = (int i) => -pi / 2 + (2 * pi * i) / n;

    // 4 concentric grid rings + spokes.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = axis;
    final outerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = axisStrong;
    for (int level = 1; level <= 4; level++) {
      final r = radius * (level / 4);
      final path = Path();
      for (int i = 0; i < n; i++) {
        final p = Offset(
          center.dx + cos(angleOf(i)) * r,
          center.dy + sin(angleOf(i)) * r,
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, level == 4 ? outerRingPaint : ringPaint);
    }
    final spokePaint = Paint()
      ..color = axis
      ..strokeWidth = 1;
    for (int i = 0; i < n; i++) {
      final outer = Offset(
        center.dx + cos(angleOf(i)) * radius,
        center.dy + sin(angleOf(i)) * radius,
      );
      canvas.drawLine(center, outer, spokePaint);
    }

    // Filled polygon for actual values.
    final polyPath = Path();
    for (int i = 0; i < n; i++) {
      final v = (values[i] / maxVal).clamp(0.0, 1.0);
      final r = radius * v;
      final p = Offset(
        center.dx + cos(angleOf(i)) * r,
        center.dy + sin(angleOf(i)) * r,
      );
      if (i == 0) {
        polyPath.moveTo(p.dx, p.dy);
      } else {
        polyPath.lineTo(p.dx, p.dy);
      }
    }
    polyPath.close();

    // Soft gradient fill.
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          fill.withValues(alpha: 0.55),
          fill.withValues(alpha: 0.20),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(polyPath, fillPaint);

    final strokePaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(polyPath, strokePaint);

    // Vertex markers.
    for (int i = 0; i < n; i++) {
      final v = (values[i] / maxVal).clamp(0.0, 1.0);
      final r = radius * v;
      final p = Offset(
        center.dx + cos(angleOf(i)) * r,
        center.dy + sin(angleOf(i)) * r,
      );
      canvas.drawCircle(p, 4, Paint()..color = fill);
      canvas.drawCircle(
        p,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    // Axis labels.
    for (int i = 0; i < n; i++) {
      final outer = Offset(
        center.dx + cos(angleOf(i)) * (radius + 16),
        center.dy + sin(angleOf(i)) * (radius + 16),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${axes[i].label}\n${values[i]}m',
          style: TextStyle(
            color: label,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      tp.paint(
        canvas,
        Offset(outer.dx - tp.width / 2, outer.dy - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.values != values || old.maxVal != maxVal;
}
