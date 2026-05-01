import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'storage.dart';
import 'tts_service.dart';

enum BreathPattern { box, fourSevenEight, triangle, coherent }

class _Phase {
  final String label;
  final int seconds;
  final double targetScale;
  const _Phase(this.label, this.seconds, this.targetScale);
}

class _PatternConfig {
  final BreathPattern type;
  final String name;
  final String tagline;
  final String description;
  final List<_Phase> phases;
  const _PatternConfig({
    required this.type,
    required this.name,
    required this.tagline,
    required this.description,
    required this.phases,
  });
}

const _patterns = <_PatternConfig>[
  _PatternConfig(
    type: BreathPattern.box,
    name: 'Box · 4·4·4·4',
    tagline: 'Steady, balanced focus',
    description: 'Inhale, hold, exhale, hold — each 4 seconds. Used by Navy SEALs to lock in focus.',
    phases: [
      _Phase('Inhale', 4, 1.0),
      _Phase('Hold', 4, 1.0),
      _Phase('Exhale', 4, 0.5),
      _Phase('Hold', 4, 0.5),
    ],
  ),
  _PatternConfig(
    type: BreathPattern.fourSevenEight,
    name: '4·7·8 · Calming',
    tagline: 'Wind down, fall asleep',
    description: 'Inhale 4, hold 7, exhale 8. Slows the nervous system fast.',
    phases: [
      _Phase('Inhale', 4, 1.0),
      _Phase('Hold', 7, 1.0),
      _Phase('Exhale', 8, 0.5),
    ],
  ),
  _PatternConfig(
    type: BreathPattern.triangle,
    name: 'Triangle · 4·4·4',
    tagline: 'Gentle reset',
    description: 'Three even sides — inhale, hold, exhale. Easy entry to breathwork.',
    phases: [
      _Phase('Inhale', 4, 1.0),
      _Phase('Hold', 4, 1.0),
      _Phase('Exhale', 4, 0.5),
    ],
  ),
  _PatternConfig(
    type: BreathPattern.coherent,
    name: 'Coherent · 5·5',
    tagline: 'Heart rate variability',
    description: 'Five seconds in, five seconds out — six breaths a minute, the resonant rhythm.',
    phases: [
      _Phase('Inhale', 5, 1.0),
      _Phase('Exhale', 5, 0.5),
    ],
  ),
];

class BreathingScreen extends StatefulWidget {
  final Storage storage;
  const BreathingScreen({super.key, required this.storage});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  int _patternIndex = 0;
  bool _running = false;
  int _phaseIdx = 0;
  int _phaseRemain = 0;
  int _cyclesCompleted = 0;
  int _totalElapsed = 0;
  Timer? _ticker;
  late AnimationController _controller;
  Animation<double> _scaleAnim =
      const AlwaysStoppedAnimation<double>(0.5);
  final TtsService _tts = TtsService();
  bool _ttsReady = false;

  _PatternConfig get _config => _patterns[_patternIndex];
  _Phase get _phase => _config.phases[_phaseIdx];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
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
      _phaseIdx = 0;
      _cyclesCompleted = 0;
      _totalElapsed = 0;
    });
    _enterPhase(0, fromScale: 0.5);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _phaseRemain -= 1;
        _totalElapsed += 1;
      });
      if (_phaseRemain <= 0) _advancePhase();
    });
  }

  void _enterPhase(int idx, {required double fromScale}) {
    final phase = _config.phases[idx];
    setState(() {
      _phaseIdx = idx;
      _phaseRemain = phase.seconds;
    });
    _controller.duration = Duration(seconds: phase.seconds);
    _scaleAnim = Tween<double>(begin: fromScale, end: phase.targetScale)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward(from: 0);
    _tts.speak(phase.label);
    HapticFeedback.selectionClick();
  }

  void _advancePhase() {
    final fromScale = _phase.targetScale;
    final nextIdx = (_phaseIdx + 1) % _config.phases.length;
    if (nextIdx == 0) _cyclesCompleted += 1;
    _enterPhase(nextIdx, fromScale: fromScale);
  }

  Future<void> _stop() async {
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    _controller.stop();
    await _tts.stop();
    final elapsed = _totalElapsed;
    final cycles = _cyclesCompleted;
    setState(() {
      _running = false;
    });
    if (elapsed >= 30) {
      await widget.storage.addSession(SessionRecord(
        completedAt: DateTime.now(),
        planTitle: 'Breathing · ${_config.name}',
        category: ExerciseCategory.breath,
        seconds: elapsed,
      ));
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🫁', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text('Breath complete',
                    style: Theme.of(ctx)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                    '$cycles cycle${cycles == 1 ? '' : 's'} · ${(elapsed / 60).toStringAsFixed(1)} min logged.',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(true);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breathing room'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: _running ? _runningBody(scheme) : _setupBody(scheme),
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
              colors: [const Color(0xFF64B5F6), scheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Text('🫁', style: TextStyle(fontSize: 48)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Breathe with the circle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.1)),
                    const SizedBox(height: 4),
                    Text(
                      'Pick a pattern and follow the rhythm. Sessions ≥ 30 s log to your history.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Pick a pattern',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (int i = 0; i < _patterns.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PatternTile(
              config: _patterns[i],
              selected: _patternIndex == i,
              onTap: () => setState(() => _patternIndex = i),
            ),
          ),
        const SizedBox(height: 16),
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
            child: const Text('Start breathing',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _runningBody(ColorScheme scheme) {
    final mm = (_totalElapsed ~/ 60).toString().padLeft(2, '0');
    final ss = (_totalElapsed % 60).toString().padLeft(2, '0');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_config.name.toUpperCase(),
            style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 3)),
        const SizedBox(height: 6),
        Text('$mm:$ss · $_cyclesCompleted cycle${_cyclesCompleted == 1 ? '' : 's'}',
            style: TextStyle(
                color: scheme.onSurface, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        SizedBox(
          width: 280,
          height: 280,
          child: Center(
            child: AnimatedBuilder(
              animation: _scaleAnim,
              builder: (_, _) {
                final s = _scaleAnim.value;
                final size = 120 + s * 140;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.85),
                        scheme.primary.withValues(alpha: 0.35),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.45),
                        blurRadius: 32 * s,
                        spreadRadius: 6 * s,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_phase.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('${max(0, _phaseRemain)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              fontFeatures: [
                                FontFeature.tabularFigures()
                              ],
                              height: 1)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 28),
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
        Text('Session is logged after 30 seconds.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _PatternTile extends StatelessWidget {
  final _PatternConfig config;
  final bool selected;
  final VoidCallback onTap;
  const _PatternTile({
    required this.config,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(config.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(config.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text(config.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
