import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'exercise_library.dart';
import 'models.dart';
import 'session_screen.dart';
import 'storage.dart';
import 'transitions.dart';
import 'tts_service.dart';

class FocusScreen extends StatefulWidget {
  final Storage storage;
  const FocusScreen({super.key, required this.storage});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  static const _workOptions = [15, 25, 45, 60];
  static const _breakOptions = [2, 3, 5];

  int _workMinutes = 25;
  int _breakMinutes = 3;

  bool _running = false;
  int _secondsLeft = 0;
  int _totalSeconds = 0;
  Timer? _timer;
  final TtsService _tts = TtsService();
  bool _ttsReady = false;

  @override
  void dispose() {
    _timer?.cancel();
    _tts.dispose();
    super.dispose();
  }

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    await _tts.init(
      personality:
          CoachPersonality.values[widget.storage.coachPersonalityIndex],
    );
    _ttsReady = true;
  }

  void _start() async {
    await _ensureTts();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _running = true;
      _totalSeconds = _workMinutes * 60;
      _secondsLeft = _totalSeconds;
    });
    _tts.speak('Focus block started. $_workMinutes minutes.');
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) {
        t.cancel();
        _onWorkComplete();
      }
    });
  }

  void _stop() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() => _running = false);
  }

  Future<void> _onWorkComplete() async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    await _tts.speak('Focus block complete. Time for a movement break.');
    if (!mounted) return;
    final goBreak = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛎️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text('Focus block complete',
                style: Theme.of(ctx)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                'Stand up, stretch, breathe. We\'ll guide you through a $_breakMinutes-minute break.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(ctx).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Skip break'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start break'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _secondsLeft = 0;
    });
    if (goBreak == true) {
      final plan = ExerciseLibrary.buildQuickPlan(
        ExerciseCategory.stretch,
        targetSeconds: _breakMinutes * 60,
      );
      await Navigator.of(context).push(FadeThroughRoute(
        builder: (_) =>
            SessionScreen(plan: plan, storage: widget.storage),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _totalSeconds == 0
        ? 0.0
        : (1 - (_secondsLeft / _totalSeconds)).clamp(0.0, 1.0);
    final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus mode'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: _running
              ? _runningBody(scheme, progress, mm, ss)
              : _setupBody(scheme),
        ),
      ),
    );
  }

  Widget _setupBody(ColorScheme scheme) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 48)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Focus + move',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.1)),
                    const SizedBox(height: 4),
                    Text(
                        'Pomodoro-style focus blocks with an automatic movement break at the end.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Work duration',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final m in _workOptions)
              _OptionChip(
                label: '$m min',
                selected: _workMinutes == m,
                onTap: () => setState(() => _workMinutes = m),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Text('Movement break',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final m in _breakOptions)
              _OptionChip(
                label: '$m min',
                selected: _breakMinutes == m,
                onTap: () => setState(() => _breakMinutes = m),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Keep the app open. When the timer ends we\'ll prompt you with a guided $_breakMinutes-minute break.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _start,
            child: Text('Start $_workMinutes-min focus',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _runningBody(
      ColorScheme scheme, double progress, String mm, String ss) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('FOCUS',
            style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 4)),
        const SizedBox(height: 8),
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 260,
                height: 260,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 700),
                  builder: (_, val, _) => CircularProgressIndicator(
                    value: val,
                    strokeWidth: 12,
                    backgroundColor: scheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$mm:$ss',
                      style: TextStyle(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: scheme.onSurface,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1)),
                  const SizedBox(height: 6),
                  Text('Stay with it',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
          style: OutlinedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          onPressed: _stop,
        ),
        const SizedBox(height: 12),
        Text('Break of $_breakMinutes min queued after the block.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                fontWeight:
                    selected ? FontWeight.w900 : FontWeight.w700,
                color: selected ? Colors.white : scheme.onSurface,
              )),
        ),
      ),
    );
  }
}
