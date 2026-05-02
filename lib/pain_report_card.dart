import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'models.dart';
import 'storage.dart';

/// 1080x1920 portrait card summarising the last 30 days of pain entries.
/// Designed to be screenshot-shared with a physiotherapist or kept for
/// progress journaling.
class PainReportCard extends StatelessWidget {
  final PainReportData data;
  const PainReportCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1B3A),
            Color(0xFF3B1E5A),
            Color(0xFFD84315),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
              top: -180, right: -180, child: _bubble(520, 0.10)),
          Positioned(
              bottom: -120, left: -160, child: _bubble(420, 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(70, 80, 70, 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6F61), Color(0xFFFFC107)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🩹',
                          style: TextStyle(fontSize: 50)),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pain report',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 56,
                                height: 1,
                                letterSpacing: -1,
                              )),
                          const SizedBox(height: 6),
                          Text(
                            '30-day trend · ${df.format(data.generatedAt)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w600,
                              fontSize: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: _statBlock(
                        emoji: '🔥',
                        value: data.hottestArea?.label ?? '—',
                        label: data.hottestArea == null
                            ? 'No flare-ups'
                            : '${data.hottestAvg.toStringAsFixed(1)}/10 avg',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _statBlock(
                        emoji: '📉',
                        value: data.improvedArea?.label ?? '—',
                        label: data.improvedArea == null
                            ? 'Keep logging'
                            : '−${data.improvedDelta.toStringAsFixed(1)} pts',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _statBlock(
                        emoji: '📅',
                        value: '${data.daysLogged}',
                        label: 'days logged',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 2),
                    ),
                    padding: const EdgeInsets.fromLTRB(36, 30, 36, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Last 30 days',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                            )),
                        const SizedBox(height: 18),
                        Expanded(
                          child: data.areaSeries.isEmpty
                              ? Center(
                                  child: Text(
                                    'No pain entries logged yet.',
                                    style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.7),
                                      fontSize: 28,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: data.areaSeries.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 18),
                                  itemBuilder: (_, i) {
                                    final entry = data.areaSeries[i];
                                    return _AreaTrendRow(entry: entry);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF29B6F6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🌱',
                          style: TextStyle(fontSize: 30)),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        'Tracked with MoveMate · adaptive recovery coach',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _statBlock(
      {required String emoji, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.20), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 36,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaTrendRow extends StatelessWidget {
  final PainAreaSeries entry;
  const _AreaTrendRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(entry.average);
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: color.withValues(alpha: 0.55), width: 2),
          ),
          child: Text(entry.area.emoji,
              style: const TextStyle(fontSize: 30)),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.area.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    height: 1.1,
                  )),
              const SizedBox(height: 4),
              Text(
                'avg ${entry.average.toStringAsFixed(1)} · peak ${entry.peak}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _SparklinePainter(entry.values, color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: entry.delta < 0
                ? const Color(0xFF4CAF50).withValues(alpha: 0.25)
                : entry.delta > 0
                    ? const Color(0xFFE53935).withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            entry.delta == 0
                ? '±0'
                : (entry.delta < 0
                    ? '−${entry.delta.abs().toStringAsFixed(1)}'
                    : '+${entry.delta.toStringAsFixed(1)}'),
            style: TextStyle(
              color: entry.delta < 0
                  ? const Color(0xFFB9F6CA)
                  : entry.delta > 0
                      ? const Color(0xFFFFCDD2)
                      : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
      ],
    );
  }
}

Color _severityColor(double avg) {
  if (avg <= 0) return const Color(0xFF9E9E9E);
  if (avg < 3) return const Color(0xFFFFB74D);
  if (avg < 6) return const Color(0xFFFF8A65);
  return const Color(0xFFE53935);
}

class _SparklinePainter extends CustomPainter {
  final List<int?> values;
  final Color color;
  _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = 10.0;
    final stepX = values.length > 1 ? size.width / (values.length - 1) : 0.0;

    final baseline = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2;
    canvas.drawLine(
        Offset(0, size.height - 1),
        Offset(size.width, size.height - 1),
        baseline);

    final path = Path();
    final fillPath = Path();
    bool started = false;
    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final x = stepX * i;
      final y = size.height - (v / maxVal) * size.height;
      if (!started) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    if (!started) return;

    final lastIdx = values.lastIndexWhere((v) => v != null);
    fillPath.lineTo(stepX * lastIdx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [color.withValues(alpha: 0.55), color.withValues(alpha: 0.05)],
      );
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final x = stepX * i;
      final y = size.height - (v / maxVal) * size.height;
      canvas.drawCircle(
          Offset(x, y), i == lastIdx ? 6 : 3,
          Paint()..color = i == lastIdx ? Colors.white : color);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}

class PainReportData {
  final DateTime generatedAt;
  final List<PainAreaSeries> areaSeries;
  final BodyArea? hottestArea;
  final double hottestAvg;
  final BodyArea? improvedArea;
  final double improvedDelta;
  final int daysLogged;

  const PainReportData({
    required this.generatedAt,
    required this.areaSeries,
    required this.hottestArea,
    required this.hottestAvg,
    required this.improvedArea,
    required this.improvedDelta,
    required this.daysLogged,
  });

  factory PainReportData.fromStorage(Storage storage,
      {DateTime? now, int days = 30}) {
    final at = now ?? DateTime.now();
    final allAreas = <BodyArea>{};
    for (final entry in storage.painLog.values) {
      allAreas.addAll(entry.keys);
    }
    final list = <PainAreaSeries>[];
    for (final area in allAreas) {
      final values = storage.painSeries(area, days: days);
      final readings = values.whereType<int>().toList();
      if (readings.isEmpty) continue;
      final avg = readings.reduce((a, b) => a + b) / readings.length;
      final peak = readings.reduce((a, b) => a > b ? a : b);
      // Compare first half average to second half average for delta.
      final half = values.length ~/ 2;
      double mean(Iterable<int?> xs) {
        final r = xs.whereType<int>().toList();
        if (r.isEmpty) return 0;
        return r.reduce((a, b) => a + b) / r.length;
      }
      final firstHalf = mean(values.take(half));
      final secondHalf = mean(values.skip(half));
      final delta = (secondHalf == 0 || firstHalf == 0)
          ? 0.0
          : (secondHalf - firstHalf);
      list.add(PainAreaSeries(
        area: area,
        values: values,
        average: avg,
        peak: peak,
        delta: delta,
      ));
    }
    list.sort((a, b) => b.average.compareTo(a.average));
    final top = list.length > 5 ? list.sublist(0, 5) : list;

    BodyArea? hottest;
    double hottestAvg = 0;
    if (list.isNotEmpty) {
      hottest = list.first.area;
      hottestAvg = list.first.average;
    }

    BodyArea? improved;
    double improvedDelta = 0;
    for (final s in list) {
      if (s.delta < improvedDelta) {
        improvedDelta = s.delta;
        improved = s.area;
      }
    }

    final daysLogged = storage.painLog.entries.where((e) {
      final parts = e.key.split('-');
      if (parts.length != 3) return false;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) return false;
      final dt = DateTime(y, m, d);
      return at.difference(dt).inDays.abs() < days;
    }).length;

    return PainReportData(
      generatedAt: at,
      areaSeries: top,
      hottestArea: hottest,
      hottestAvg: hottestAvg,
      improvedArea: improved,
      improvedDelta: improvedDelta.abs(),
      daysLogged: daysLogged,
    );
  }
}

class PainAreaSeries {
  final BodyArea area;
  final List<int?> values;
  final double average;
  final int peak;
  final double delta;
  const PainAreaSeries({
    required this.area,
    required this.values,
    required this.average,
    required this.peak,
    required this.delta,
  });
}

Future<Uint8List> renderPainReport(
    BuildContext context, PainReportData data) async {
  final completer = Completer<Uint8List>();
  final repaintKey = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -10000,
      top: -10000,
      child: Material(
        color: Colors.transparent,
        child: RepaintBoundary(
          key: repaintKey,
          child: PainReportCard(data: data),
        ),
      ),
    ),
  );
  overlay.insert(entry);

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 90));
      final ctx = repaintKey.currentContext;
      if (ctx == null) {
        completer.completeError('Repaint context missing');
        entry.remove();
        return;
      }
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        completer.completeError('Encode failed');
      } else {
        completer.complete(byteData.buffer.asUint8List());
      }
    } catch (e) {
      completer.completeError(e);
    } finally {
      entry.remove();
    }
  });
  return completer.future;
}

Future<void> sharePainReport(BuildContext context, Storage storage) async {
  final data = PainReportData.fromStorage(storage);
  final bytes = await renderPainReport(context, data);
  final dir = await getTemporaryDirectory();
  final filename =
      'movemate_pain_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png', name: filename)],
    text: '30-day pain trend from MoveMate 🩹',
  );
}
