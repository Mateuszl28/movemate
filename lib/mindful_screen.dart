import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'storage.dart';
import 'tts_service.dart';

/// 5-4-3-2-1 grounding exercise: name 5 things you see, 4 you can touch,
/// 3 you can hear, 2 you can smell, 1 you can taste. Each step lingers for
/// roughly the count × 4 seconds with TTS prompting. Tap "Got it" to advance.
class MindfulScreen extends StatefulWidget {
  final Storage storage;
  const MindfulScreen({super.key, required this.storage});

  @override
  State<MindfulScreen> createState() => _MindfulScreenState();
}

class _Step {
  final int count;
  final String sense;
  final String prompt;
  final String emoji;
  final List<Color> gradient;
  const _Step({
    required this.count,
    required this.sense,
    required this.prompt,
    required this.emoji,
    required this.gradient,
  });
}

const _steps = <_Step>[
  _Step(
    count: 5,
    sense: 'see',
    prompt: 'Name five things you can see right now.',
    emoji: '👁️',
    gradient: [Color(0xFF7B5CFF), Color(0xFF4A6CFF)],
  ),
  _Step(
    count: 4,
    sense: 'touch',
    prompt: 'Name four things you can feel — clothes, chair, breath.',
    emoji: '✋',
    gradient: [Color(0xFF26A69A), Color(0xFF00796B)],
  ),
  _Step(
    count: 3,
    sense: 'hear',
    prompt: 'Name three sounds — close, distant, your breath.',
    emoji: '👂',
    gradient: [Color(0xFFFFB74D), Color(0xFFFF8A3A)],
  ),
  _Step(
    count: 2,
    sense: 'smell',
    prompt: 'Name two things you can smell — air, coffee, skin.',
    emoji: '👃',
    gradient: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
  ),
  _Step(
    count: 1,
    sense: 'taste',
    prompt: 'Name one thing you can taste — water, mint, your lips.',
    emoji: '👄',
    gradient: [Color(0xFFE57373), Color(0xFFD84315)],
  ),
];

class _MindfulScreenState extends State<MindfulScreen> {
  bool _running = false;
  bool _completed = false;
  int _stepIdx = 0;
  int _stepRemain = 0;
  int _totalElapsed = 0;
  Timer? _ticker;
  final TtsService _tts = TtsService();
  bool _ttsReady = false;

  _Step get _step => _steps[_stepIdx];

  @override
  void dispose() {
    _ticker?.cancel();
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
      _stepIdx = 0;
      _stepRemain = _step.count * 4;
      _totalElapsed = 0;
    });
    _tts.speak(_step.prompt);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _stepRemain -= 1;
        _totalElapsed += 1;
      });
      if (_stepRemain <= 0) _advance();
    });
  }

  void _advance() {
    HapticFeedback.selectionClick();
    final next = _stepIdx + 1;
    if (next >= _steps.length) {
      _finish();
      return;
    }
    setState(() {
      _stepIdx = next;
      _stepRemain = _step.count * 4;
    });
    _tts.speak(_step.prompt);
  }

  Future<void> _finish() async {
    _ticker?.cancel();
    await _tts.stop();
    HapticFeedback.lightImpact();
    final elapsed = _totalElapsed;
    await widget.storage.logMindfulMoment();
    if (elapsed >= 30) {
      await widget.storage.addSession(SessionRecord(
        completedAt: DateTime.now(),
        planTitle: 'Mindfulness · 5-4-3-2-1',
        category: ExerciseCategory.breath,
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
    if (!mounted) return;
    setState(() {
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindful moment'),
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
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Text('🧘', style: TextStyle(fontSize: 48)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('5-4-3-2-1 grounding',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1)),
                      const SizedBox(height: 4),
                      Text(
                        'Anchor yourself with five senses. Pulls you out of spinning thoughts in about a minute.',
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
          Text('What you\'ll do',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (int i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(_steps[i].emoji,
                        style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          '${_steps[i].count} things you can ${_steps[i].sense}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Begin grounding',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunning() {
    final step = _step;
    return Padding(
      key: ValueKey('step$_stepIdx'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Text('STEP ${_stepIdx + 1} OF ${_steps.length}',
              style: const TextStyle(
                  letterSpacing: 3,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  color: Colors.white60)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: step.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: step.gradient.last.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(step.emoji, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text('${step.count}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 96,
                        fontWeight: FontWeight.w900,
                        height: 1)),
                const SizedBox(height: 4),
                Text('things you can ${step.sense}',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(step.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _stopEarly,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Stop'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text('Got it · ${_stepRemain.clamp(0, 99)}s',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _advance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDone() {
    final scheme = Theme.of(context).colorScheme;
    final mindful = widget.storage.mindfulToday;
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
                child: Text('🧘', style: TextStyle(fontSize: 56))),
          ),
          const SizedBox(height: 24),
          const Text('Grounded',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
              mindful == 1
                  ? 'First grounding moment logged today.'
                  : '$mindful grounding moments logged today.',
              style: TextStyle(
                  color: scheme.onSurfaceVariant, fontSize: 14)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
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
