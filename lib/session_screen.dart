import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'achievements.dart';
import 'models.dart';
import 'mood_picker.dart';
import 'note_picker.dart';
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
  int? _moodBefore;
  int? _moodAfter;
  final TtsService _tts = TtsService();

  Exercise get _current => widget.plan.exercises[_currentIndex];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _current.seconds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runMoodFlowAndStart();
    });
  }

  Future<void> _runMoodFlowAndStart() async {
    final mb = await askForMood(
      context,
      title: 'How do you feel right now?',
      subtitle:
          'A quick check-in helps us see how movement changes your mood.',
      confirmLabel: 'Start session',
      skipLabel: 'Skip',
    );
    if (!mounted) return;
    setState(() {
      _moodBefore = mb;
    });
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

    if (!mounted) return;
    final ma = await askForMood(
      context,
      title: 'How do you feel now?',
      subtitle: 'Tap how you feel after the session.',
      confirmLabel: 'Save',
      skipLabel: 'Skip',
    );
    _moodAfter = ma;

    if (!mounted) return;
    final note = await askForSessionNote(context);

    await widget.storage.addSession(SessionRecord(
      completedAt: DateTime.now(),
      planTitle: widget.plan.title,
      category: widget.plan.primaryCategory,
      seconds: widget.plan.totalSeconds,
      moodBefore: _moodBefore,
      moodAfter: _moodAfter,
      note: note,
    ));
    final newFreezes = await widget.storage.grantFreezesForStreak();
    final streakAfterAdd = widget.storage.currentStreak;
    final lastCelebrated = widget.storage.lastCelebratedStreak;
    final milestone = _milestoneCrossed(lastCelebrated, streakAfterAdd);
    if (milestone != null) {
      await widget.storage.setLastCelebratedStreak(milestone);
    }

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
    final delta = (_moodBefore != null && _moodAfter != null)
        ? _moodAfter! - _moodBefore!
        : null;
    final streakAfter = widget.storage.currentStreak;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CompletionDialog(
        plan: widget.plan,
        moodDelta: delta,
        streak: streakAfter,
        freezesEarned: newFreezes,
      ),
    );
    if (!mounted) return;
    if (milestone != null) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _StreakMilestoneDialog(milestone: milestone),
      );
      if (!mounted) return;
    }
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            Text(_current.instruction,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
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

int? _milestoneCrossed(int last, int current) {
  const milestones = [7, 14, 30, 60, 100, 200, 365];
  for (final m in milestones) {
    if (current >= m && last < m) return m;
  }
  return null;
}

class _StreakMilestoneDialog extends StatefulWidget {
  final int milestone;
  const _StreakMilestoneDialog({required this.milestone});

  @override
  State<_StreakMilestoneDialog> createState() => _StreakMilestoneDialogState();
}

class _StreakMilestoneDialogState extends State<_StreakMilestoneDialog> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.milestone) {
      case 7:
        return 'First week — done!';
      case 14:
        return 'Two weeks of momentum';
      case 30:
        return 'A whole month of you';
      case 60:
        return 'Two months strong';
      case 100:
        return '100 days. Legendary.';
      case 200:
        return '200 days — top tier';
      case 365:
        return 'A year of moving!';
      default:
        return '${widget.milestone}-day streak!';
    }
  }

  String get _subtitle {
    switch (widget.milestone) {
      case 7:
        return 'You moved every single day this week. That\'s how habits start.';
      case 14:
        return 'Consistency over intensity. You\'re proving that.';
      case 30:
        return 'A month is when habits become identity. Welcome to the other side.';
      case 60:
        return 'You\'re past every research paper\'s "habit threshold."';
      case 100:
        return 'Triple digits of self-care. Few make it here.';
      case 200:
        return 'Your daily ritual is just… who you are now.';
      case 365:
        return 'A full year. Take a breath and feel that win.';
      default:
        return 'Keep going — every day counts.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          contentPadding: const EdgeInsets.fromLTRB(28, 32, 28, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A3A), Color(0xFFFFD449)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A3A).withValues(alpha: 0.6),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 40)),
                      Text('${widget.milestone}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(_title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(_subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4)),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I\'m proud',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.04,
            numberOfParticles: 30,
            maxBlastForce: 32,
            minBlastForce: 12,
            gravity: 0.22,
            shouldLoop: false,
            colors: const [
              Color(0xFFFF8A3A),
              Color(0xFFFFD449),
              Color(0xFF2EB872),
              Color(0xFF64B5F6),
              Color(0xFFE57373),
            ],
          ),
        ),
      ],
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

class _CompletionDialog extends StatefulWidget {
  final WorkoutPlan plan;
  final int? moodDelta;
  final int streak;
  final int freezesEarned;
  const _CompletionDialog({
    required this.plan,
    required this.streak,
    required this.freezesEarned,
    this.moodDelta,
  });

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final delta = widget.moodDelta;
    final mood = delta == null
        ? ''
        : delta > 0
            ? ' Mood +$delta ✨'
            : delta == 0
                ? ' Mood steady 🌿'
                : ' Mood $delta 💭';
    final streak = widget.streak >= 2 ? '\nStreak: ${widget.streak} 🔥' : '';
    final text =
        'Just did a ${widget.plan.formattedDuration} ${widget.plan.title} on MoveMate.$mood$streak\n#MoveMate #PhysTech';
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final delta = widget.moodDelta;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              Text(
                  '${widget.plan.title} • ${widget.plan.formattedDuration}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant)),
              if (delta != null) ...[
                const SizedBox(height: 14),
                _MoodDeltaBadge(delta: delta),
              ],
              if (widget.freezesEarned > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('❄️',
                          style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        widget.freezesEarned == 1
                            ? '+1 streak freeze earned'
                            : '+${widget.freezesEarned} streak freezes earned',
                        style: const TextStyle(
                          color: Color(0xFF0369A1),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                  widget.streak >= 2
                      ? '${widget.streak}-day streak — keep it alive!'
                      : 'Your streak is growing. Great job!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.ios_share),
              label: const Text('Share'),
              onPressed: _share,
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Awesome'),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 18,
            maxBlastForce: 25,
            minBlastForce: 8,
            gravity: 0.25,
            shouldLoop: false,
            colors: const [
              Color(0xFF2EB872),
              Color(0xFF7BC67E),
              Color(0xFFFFB74D),
              Color(0xFF64B5F6),
              Color(0xFFE57373),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoodDeltaBadge extends StatelessWidget {
  final int delta;
  const _MoodDeltaBadge({required this.delta});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final positive = delta > 0;
    final neutral = delta == 0;
    final color = positive
        ? const Color(0xFF2EB872)
        : neutral
            ? scheme.onSurfaceVariant
            : const Color(0xFFE57373);
    final emoji = positive ? '✨' : (neutral ? '🌿' : '💭');
    final label = positive
        ? 'Mood +$delta — movement helped!'
        : neutral
            ? 'Mood stayed steady — nice grounding.'
            : 'Mood ${delta.toString()} — a deeper reset might help.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    )),
          ),
        ],
      ),
    );
  }
}
