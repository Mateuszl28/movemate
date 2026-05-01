import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'achievements.dart';
import 'models.dart';
import 'storage.dart';
import 'tts_service.dart';

class SessionScreen extends StatefulWidget {
  final WorkoutPlan plan;
  final Storage storage;

  const SessionScreen({super.key, required this.plan, required this.storage});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _remainingSeconds = 0;
  bool _isPaused = false;
  bool _completed = false;
  Timer? _timer;
  Timer? _countdownTimer;
  int? _countdown;
  final TtsService _tts = TtsService();

  Exercise get _current => widget.plan.exercises[_currentIndex];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _current.seconds;
    _initTtsAndStart();
  }

  Future<void> _initTtsAndStart() async {
    await _tts.init();
    if (!mounted) return;
    _runPreWorkoutCountdown();
  }

  void _runPreWorkoutCountdown() {
    setState(() => _countdown = 3);
    _tts.speak('Get ready. ${_current.name}.');
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final next = (_countdown ?? 0) - 1;
      if (next > 0) {
        setState(() => _countdown = next);
        _tts.speak('$next');
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.selectionClick();
      } else {
        t.cancel();
        _countdownTimer = null;
        _tts.speak('Go!');
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        setState(() => _countdown = null);
        _announceCurrent();
        _startTimer();
      }
    });
  }

  void _announceCurrent() {
    _tts.speak('${_current.name}. ${_current.instruction}');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _tts.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || !mounted) return;
      setState(() {
        _remainingSeconds -= 1;
      });
      if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
        HapticFeedback.selectionClick();
        _tts.speak('$_remainingSeconds');
      }
      if (_remainingSeconds <= 0) {
        _next();
      }
    });
  }

  void _next() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    if (_currentIndex < widget.plan.exercises.length - 1) {
      setState(() {
        _currentIndex += 1;
        _remainingSeconds = _current.seconds;
      });
      _announceCurrent();
    } else {
      _finish();
    }
  }

  void _previous() {
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex -= 1;
      _remainingSeconds = _current.seconds;
    });
    _announceCurrent();
  }

  Future<void> _finish() async {
    _timer?.cancel();
    if (_completed) return;
    _completed = true;
    HapticFeedback.heavyImpact();
    await _tts.speak('Well done! Session complete.');
    await widget.storage.addSession(SessionRecord(
      completedAt: DateTime.now(),
      planTitle: widget.plan.title,
      category: widget.plan.primaryCategory,
      seconds: widget.plan.totalSeconds,
    ));

    final earned = AchievementCatalog.earned(
      widget.storage.sessions,
      widget.storage.currentStreak,
      widget.storage.dailyGoalMinutes,
    );
    final seen = widget.storage.seenAchievements;
    final newlyEarned =
        earned.where((a) => !seen.contains(a.id)).toList();
    if (newlyEarned.isNotEmpty) {
      await widget.storage.markAchievementsSeen(newlyEarned.map((a) => a.id));
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(plan: widget.plan),
    );
    if (!mounted) return;
    if (newlyEarned.isNotEmpty) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AchievementsUnlockedDialog(achievements: newlyEarned),
      );
      if (!mounted) return;
    }
    Navigator.of(context).pop(true);
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End session?'),
        content: const Text('Progress from this session will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _current.category.accent;
    final progress = 1 - (_remainingSeconds / _current.seconds);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmExit() && mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: accent.withValues(alpha: 0.10),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        if (await _confirmExit() && mounted) {
                          Navigator.of(context).pop(false);
                        }
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.plan.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            'Step ${_currentIndex + 1} of ${widget.plan.exercises.length}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: _tts.enabled ? 'Mute voice' : 'Enable voice',
                      icon: Icon(_tts.enabled
                          ? Icons.volume_up
                          : Icons.volume_off),
                      onPressed: () {
                        setState(() => _tts.enabled = !_tts.enabled);
                        if (!_tts.enabled) _tts.stop();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (_currentIndex + progress) /
                    widget.plan.exercises.length,
                minHeight: 6,
                backgroundColor: Colors.black.withValues(alpha: 0.06),
                color: accent,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TimerRing(
                        progress: progress,
                        accent: accent,
                        secondsLeft: _remainingSeconds,
                        emoji: _current.emoji,
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          children: [
                            Text(_current.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            Text(_current.instruction,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundIconButton(
                      icon: Icons.skip_previous,
                      onTap: _currentIndex == 0 ? null : _previous,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isPaused = !_isPaused);
                        HapticFeedback.lightImpact();
                        if (_isPaused) _tts.stop();
                      },
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.skip_next,
                      onTap: _next,
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
            if (_countdown != null)
              _CountdownOverlay(value: _countdown!, accent: accent),
          ],
        ),
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  final int value;
  final Color accent;
  const _CountdownOverlay({required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(value),
            tween: Tween(begin: 0.6, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Get ready',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 16),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 110,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final double progress;
  final Color accent;
  final int secondsLeft;
  final String emoji;
  const _TimerRing({
    required this.progress,
    required this.accent,
    required this.secondsLeft,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (_, val, _) => CircularProgressIndicator(
                value: val,
                strokeWidth: 12,
                backgroundColor: accent.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 6),
              Text('${secondsLeft.clamp(0, 999)}s',
                  style: TextStyle(
                      color: accent,
                      fontSize: 36,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: disabled
                ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                : Theme.of(context).colorScheme.onSurface,
            size: 28),
      ),
    );
  }
}

class _AchievementsUnlockedDialog extends StatelessWidget {
  final List<Achievement> achievements;
  const _AchievementsUnlockedDialog({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
              achievements.length == 1
                  ? 'Achievement unlocked!'
                  : '${achievements.length} achievements unlocked!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...achievements.map((a) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text(a.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Nice!'),
        ),
      ],
    );
  }
}

class _CompletionDialog extends StatelessWidget {
  final WorkoutPlan plan;
  const _CompletionDialog({required this.plan});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text('Session complete!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('${plan.title} • ${plan.formattedDuration}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text('Your streak is growing. Great job!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Awesome'),
        ),
      ],
    );
  }
}
