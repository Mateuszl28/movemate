import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'storage.dart';
import 'tts_service.dart';

/// A short standing-and-walking break. Pick a duration, follow the cues,
/// and the break logs as a cardio session if at least 30 seconds elapse.
class WalkBreakScreen extends StatefulWidget {
  final Storage storage;
  const WalkBreakScreen({super.key, required this.storage});

  @override
  State<WalkBreakScreen> createState() => _WalkBreakScreenState();
}

class _Duration {
  final int seconds;
  final String label;
  final String tagline;
  const _Duration(this.seconds, this.label, this.tagline);
}

const _durations = <_Duration>[
  _Duration(60, '1 min', 'Stand up, loop the room.'),
  _Duration(120, '2 min', 'Walk to a window, breathe deep.'),
  _Duration(300, '5 min', 'Get a drink, take a hallway lap.'),
];

class _WalkBreakScreenState extends State<WalkBreakScreen>
    with SingleTickerProviderStateMixin {
  int _durIdx = 1;
  bool _running = false;
  bool _completed = false;
  int _remaining = 0;
  int _elapsed = 0;
  Timer? _ticker;
  late final AnimationController _bounce;
  final TtsService _tts = TtsService();
  bool _ttsReady = false;
  bool _midwaySpoken = false;
  bool _endingSpoken = false;

  _Duration get _dur => _durations[_durIdx];

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _bounce.dispose();
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
      _remaining = _dur.seconds;
      _elapsed = 0;
      _midwaySpoken = false;
      _endingSpoken = false;
    });
    _tts.speak('Stand up. Walk somewhere. I\'ll cue you.');
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _remaining -= 1;
        _elapsed += 1;
      });
      if (!_midwaySpoken && _elapsed >= _dur.seconds ~/ 2) {
        _midwaySpoken = true;
        _tts.speak('Halfway there. Let your shoulders drop.');
      }
      if (!_endingSpoken && _remaining == 10) {
        _endingSpoken = true;
        _tts.speak('Ten seconds — start drifting back to your chair.');
      }
      if (_remaining <= 0) _finish();
    });
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    await _tts.stop();
    HapticFeedback.lightImpact();
    final elapsed = _elapsed;
    if (elapsed >= 30) {
      await widget.storage.addSession(SessionRecord(
        completedAt: DateTime.now(),
        planTitle: 'Walk break · ${_dur.label}',
        category: ExerciseCategory.cardio,
        seconds: elapsed,
      ));
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _completed = true;
    });
  }

  Future<void> _stopEarly() async {
    _ticker?.cancel();
    await _tts.stop();
    final elapsed = _elapsed;
    if (elapsed >= 30) {
      await widget.storage.addSession(SessionRecord(
        completedAt: DateTime.now(),
        planTitle: 'Walk break · ${_dur.label}',
        category: ExerciseCategory.cardio,
        seconds: elapsed,
      ));
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _completed = elapsed >= 30;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk break'),
        backgroundColor: Colors.transparent,
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      key: const ValueKey('intro'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE57373), Color(0xFFD84315)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Text('🚶', style: TextStyle(fontSize: 48)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Walk it off',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1)),
                      const SizedBox(height: 4),
                      Text(
                        'Get up, move your legs, and reset your circulation. Logs as a cardio micro-session.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Pick a length',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (int i = 0; i < _durations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DurationTile(
                duration: _durations[i],
                selected: _durIdx == i,
                onTap: () => setState(() => _durIdx = i),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start walk',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _start,
            ),
          ),
          const SizedBox(height: 8),
          Text('Logs as cardio after 30s.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildRunning() {
    final scheme = Theme.of(context).colorScheme;
    final progress = _dur.seconds == 0
        ? 0.0
        : (_elapsed / _dur.seconds).clamp(0.0, 1.0);
    final mm = (_remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (_remaining % 60).toString().padLeft(2, '0');
    return Padding(
      key: const ValueKey('running'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text('WALK · ${_dur.label.toUpperCase()}',
              style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w900,
                  fontSize: 11)),
          const Spacer(),
          AnimatedBuilder(
            animation: _bounce,
            builder: (_, _) {
              final t = _bounce.value;
              return Transform.translate(
                offset: Offset(0, -8 * t),
                child: Text('🚶',
                    style: TextStyle(fontSize: 96 + 6 * t)),
              );
            },
          ),
          const SizedBox(height: 20),
          Text('$mm:$ss',
              style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                  height: 1)),
          const SizedBox(height: 6),
          Text('${_dur.seconds - _remaining}s elapsed',
              style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (_, val, _) => LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 12),
            ),
            onPressed: _stopEarly,
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    final scheme = Theme.of(context).colorScheme;
    final mins = (_elapsed / 60);
    final logged = _elapsed >= 30;
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
              color: scheme.primary.withValues(alpha: 0.18),
            ),
            child: const Center(
                child: Text('🚶', style: TextStyle(fontSize: 56))),
          ),
          const SizedBox(height: 24),
          const Text('Walk break done',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
              logged
                  ? '${mins.toStringAsFixed(1)} min logged as cardio.'
                  : 'Too short to log — try at least 30 seconds next time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: scheme.onSurfaceVariant, fontSize: 14)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(logged),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  final _Duration duration;
  final bool selected;
  final VoidCallback onTap;
  const _DurationTile({
    required this.duration,
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(duration.label.split(' ').first,
                      style: TextStyle(
                          color: scheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(duration.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(duration.tagline,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.3)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
