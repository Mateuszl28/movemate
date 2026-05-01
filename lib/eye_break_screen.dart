import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'storage.dart';
import 'tts_service.dart';

/// 20-20-20 eye break: every 20 minutes, look 20 feet away for 20 seconds.
/// This screen guides the user through a 30-second flow with three phases:
///   1. Look far away (20s)
///   2. Slow blinks (5s)
///   3. Refocus (5s)
class EyeBreakScreen extends StatefulWidget {
  final Storage storage;
  const EyeBreakScreen({super.key, required this.storage});

  @override
  State<EyeBreakScreen> createState() => _EyeBreakScreenState();
}

class _Phase {
  final String label;
  final String prompt;
  final int seconds;
  final IconData icon;
  const _Phase(this.label, this.prompt, this.seconds, this.icon);
}

const _phases = <_Phase>[
  _Phase('Look 20 feet away',
      'Find a point in the distance — a window, a wall, anything past 6 metres.',
      20,
      Icons.visibility_outlined),
  _Phase('Slow blinks',
      'Five slow, deliberate blinks. Re-moisten your eyes.',
      5,
      Icons.remove_red_eye_outlined),
  _Phase('Refocus gently',
      'Bring your gaze back. Soft eyes, soft jaw, soft shoulders.',
      5,
      Icons.center_focus_weak_outlined),
];

class _EyeBreakScreenState extends State<EyeBreakScreen>
    with SingleTickerProviderStateMixin {
  bool _running = false;
  bool _completed = false;
  int _phaseIdx = 0;
  int _phaseRemain = 0;
  Timer? _ticker;
  late final AnimationController _pulse;
  final TtsService _tts = TtsService();
  bool _ttsReady = false;

  static int get _totalSeconds =>
      _phases.fold<int>(0, (sum, p) => sum + p.seconds);

  _Phase get _phase => _phases[_phaseIdx];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
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

  Future<void> _start() async {
    await _ensureTts();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _running = true;
      _completed = false;
      _phaseIdx = 0;
      _phaseRemain = _phases[0].seconds;
    });
    _tts.speak(_phase.prompt);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _phaseRemain -= 1;
      });
      if (_phaseRemain <= 0) _advance();
    });
  }

  void _advance() {
    final next = _phaseIdx + 1;
    if (next >= _phases.length) {
      _finish();
      return;
    }
    setState(() {
      _phaseIdx = next;
      _phaseRemain = _phases[next].seconds;
    });
    HapticFeedback.selectionClick();
    _tts.speak(_phase.prompt);
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    await _tts.stop();
    HapticFeedback.lightImpact();
    await widget.storage.logEyeBreak();
    if (!mounted) return;
    setState(() {
      _running = false;
      _completed = true;
    });
  }

  Future<void> _stopEarly() async {
    _ticker?.cancel();
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: const Text('Eye break'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _completed
              ? _buildDone()
              : _running
                  ? _buildRunning()
                  : _buildIntro(),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      key: const ValueKey('intro'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3D5A80), Color(0xFF293E66)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Text('👀', style: TextStyle(fontSize: 48)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('20-20-20 rule',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1)),
                      const SizedBox(height: 4),
                      Text(
                        'Every 20 minutes, look 20 feet away for 20 seconds. Resets eye strain, mental load, and focus.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          for (int i = 0; i < _phases.length; i++)
            _PhasePreview(index: i + 1, phase: _phases[i]),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start eye break',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _start,
            ),
          ),
          const SizedBox(height: 8),
          Text('Logs after ${_totalSeconds}s · today: ${widget.storage.eyeBreaksToday}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRunning() {
    final progress = 1 - (_phaseRemain / _phase.seconds).clamp(0.0, 1.0);
    return Padding(
      key: const ValueKey('running'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text('Phase ${_phaseIdx + 1} of ${_phases.length}',
              style: const TextStyle(
                  color: Colors.white54,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                  fontSize: 11)),
          const SizedBox(height: 6),
          Text(_phase.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) {
              final t = _pulse.value;
              final size = 200 + t * 60;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF64B5F6).withValues(alpha: 0.85),
                      const Color(0xFF1E88E5).withValues(alpha: 0.25),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF64B5F6).withValues(alpha: 0.5),
                      blurRadius: 40 + 30 * t,
                      spreadRadius: 6 * t,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_phase.icon, color: Colors.white, size: 36),
                    const SizedBox(height: 8),
                    Text('$_phaseRemain',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            fontFeatures: [FontFeature.tabularFigures()],
                            height: 1)),
                    const Text('seconds',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(_phase.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (_, val, _) => LinearProgressIndicator(
                value: val,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFF64B5F6)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            onPressed: _stopEarly,
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    final today = widget.storage.eyeBreaksToday;
    return Padding(
      key: const ValueKey('done'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF64B5F6).withValues(alpha: 0.18),
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF64B5F6), size: 72),
          ),
          const SizedBox(height: 24),
          const Text('Eyes refreshed',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
              today == 1
                  ? 'First eye break logged today.'
                  : '$today eye breaks logged today.',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF64B5F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _completed = false;
              });
              _start();
            },
            child: const Text('Run again',
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

class _PhasePreview extends StatelessWidget {
  final int index;
  final _Phase phase;
  const _PhasePreview({required this.index, required this.phase});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('$index',
                    style: const TextStyle(
                        color: Color(0xFF64B5F6),
                        fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(phase.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(phase.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${phase.seconds}s',
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
