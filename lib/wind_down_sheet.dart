import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Box-breathing wind-down — 4 cycles of inhale (4s) → hold (4s) → exhale (4s)
/// → hold (4s). Shown after intense or longer sessions to close the loop with
/// a calm reset. Returns when complete or skipped.
Future<void> showWindDown(BuildContext context, {int cycles = 4}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => _WindDownSheet(cycles: cycles),
  );
}

class _WindDownSheet extends StatefulWidget {
  final int cycles;
  const _WindDownSheet({required this.cycles});

  @override
  State<_WindDownSheet> createState() => _WindDownSheetState();
}

class _WindDownSheetState extends State<_WindDownSheet>
    with TickerProviderStateMixin {
  // Single 16-second loop for one full box-breathing cycle.
  static const _phaseSeconds = 4;
  static const _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  late final AnimationController _ctrl;
  int _completedCycles = 0;
  int _phaseIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _phaseSeconds),
    );
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.lightImpact();
        setState(() {
          _phaseIndex = (_phaseIndex + 1) % _phases.length;
          if (_phaseIndex == 0) {
            _completedCycles++;
            if (_completedCycles >= widget.cycles && mounted) {
              Navigator.of(context).maybePop();
              return;
            }
          }
        });
        _ctrl.forward(from: 0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.lightImpact();
      _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phase = _phases[_phaseIndex];
    final remaining = widget.cycles - _completedCycles;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Text('Wind-down',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                  'Box breathing · ${widget.cycles} cycle${widget.cycles == 1 ? "" : "s"} (~${widget.cycles * 16}s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              SizedBox(
                height: 260,
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => CustomPaint(
                    painter: _BoxBreathPainter(
                      progress: _ctrl.value,
                      phaseIndex: _phaseIndex,
                      activeColor: scheme.primary,
                      ringColor:
                          scheme.outline.withValues(alpha: 0.30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(phase,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(
                  'Cycle ${_completedCycles + 1} of ${widget.cycles} · $remaining left',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxBreathPainter extends CustomPainter {
  final double progress; // 0..1 of current phase
  final int phaseIndex;  // 0=inhale (top), 1=hold (right), 2=exhale (bottom), 3=hold (left)
  final Color activeColor;
  final Color ringColor;

  _BoxBreathPainter({
    required this.progress,
    required this.phaseIndex,
    required this.activeColor,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final box = Rect.fromCenter(
      center: Offset(w / 2, h / 2),
      width: w * 0.72,
      height: w * 0.72,
    );
    final radius = box.width / 2;
    final center = box.center;

    // Background square outline.
    final outline = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rrect = RRect.fromRectAndRadius(box, const Radius.circular(28));
    canvas.drawRRect(rrect, outline);

    // The orb scales with the breathing pattern: grow on inhale (0), stay
    // large on hold (1), shrink on exhale (2), stay small on hold (3).
    double scale;
    switch (phaseIndex) {
      case 0:
        scale = 0.5 + 0.5 * progress;
        break;
      case 1:
        scale = 1.0;
        break;
      case 2:
        scale = 1.0 - 0.5 * progress;
        break;
      default:
        scale = 0.5;
    }
    final orbR = radius * 0.55 * scale;
    canvas.drawCircle(
      center,
      orbR + 12,
      Paint()
        ..color = activeColor.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      center,
      orbR,
      Paint()
        ..shader = RadialGradient(colors: [
          activeColor.withValues(alpha: 0.95),
          activeColor.withValues(alpha: 0.5),
        ]).createShader(Rect.fromCircle(center: center, radius: orbR)),
    );

    // Travelling dot tracing the box (visualises position in the cycle).
    final dotPaint = Paint()..color = activeColor;
    final dotPos = _dotOnBox(box, phaseIndex, progress);
    canvas.drawCircle(dotPos, 6, dotPaint);
    canvas.drawCircle(
        dotPos,
        12,
        Paint()
          ..color = activeColor.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  Offset _dotOnBox(Rect box, int phase, double t) {
    final tt = t.clamp(0.0, 1.0);
    switch (phase) {
      case 0: // top edge: left -> right
        return Offset(box.left + box.width * tt, box.top);
      case 1: // right edge: top -> bottom
        return Offset(box.right, box.top + box.height * tt);
      case 2: // bottom edge: right -> left
        return Offset(box.right - box.width * tt, box.bottom);
      default: // left edge: bottom -> top
        return Offset(box.left, box.bottom - box.height * tt);
    }
  }

  @override
  bool shouldRepaint(covariant _BoxBreathPainter old) =>
      old.progress != progress || old.phaseIndex != phaseIndex;
}

/// Returns true if the plan deserves a wind-down — cardio category, or any
/// session that ran for at least [minSeconds].
bool shouldWindDown({
  required String category,
  required int seconds,
  int minSeconds = 5 * 60,
}) {
  if (category == 'cardio') return true;
  return seconds >= minSeconds;
}

// Avoid an unused-import warning in tests that import dart:math.
// ignore: unused_element
const _piRef = pi;
