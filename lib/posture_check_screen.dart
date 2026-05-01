import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'exercise_library.dart';
import 'models.dart';
import 'session_screen.dart';
import 'storage.dart';
import 'transitions.dart';

class _Question {
  final String prompt;
  final String hint;
  final String emoji;
  final BodyArea area;
  const _Question({
    required this.prompt,
    required this.hint,
    required this.emoji,
    required this.area,
  });
}

const _questions = <_Question>[
  _Question(
    prompt: 'Are both feet flat on the floor?',
    hint: 'Heels grounded, knees roughly at hip height.',
    emoji: '🦶',
    area: BodyArea.legs,
  ),
  _Question(
    prompt: 'Is your lower back supported?',
    hint: 'Sit back into the chair — pelvis tucked, no slumping.',
    emoji: '🪑',
    area: BodyArea.back,
  ),
  _Question(
    prompt: 'Are your shoulders relaxed and down?',
    hint: 'Drop them away from the ears. No shrugging into the screen.',
    emoji: '🤷',
    area: BodyArea.shoulders,
  ),
  _Question(
    prompt: 'Is the top of your screen at eye level?',
    hint: 'Eyes hit the top third of the display, neck neutral.',
    emoji: '🖥️',
    area: BodyArea.neck,
  ),
  _Question(
    prompt: 'Are your wrists straight and relaxed?',
    hint: 'Forearms parallel to the floor, wrists not bent up or down.',
    emoji: '✋',
    area: BodyArea.wrists,
  ),
];

class PostureCheckScreen extends StatefulWidget {
  final Storage storage;
  const PostureCheckScreen({super.key, required this.storage});

  @override
  State<PostureCheckScreen> createState() => _PostureCheckScreenState();
}

class _PostureCheckScreenState extends State<PostureCheckScreen> {
  final List<bool?> _answers = List<bool?>.filled(_questions.length, null);
  int _idx = 0;
  bool _done = false;

  int get _score {
    final yes = _answers.where((a) => a == true).length;
    return ((yes / _questions.length) * 100).round();
  }

  List<BodyArea> get _problemAreas {
    final out = <BodyArea>[];
    for (int i = 0; i < _answers.length; i++) {
      if (_answers[i] == false) out.add(_questions[i].area);
    }
    return out;
  }

  Future<void> _answer(bool yes) async {
    HapticFeedback.selectionClick();
    setState(() {
      _answers[_idx] = yes;
    });
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    if (_idx + 1 < _questions.length) {
      setState(() => _idx += 1);
    } else {
      await widget.storage.logPosture(_score);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() => _done = true);
    }
  }

  void _restart() {
    setState(() {
      for (int i = 0; i < _answers.length; i++) {
        _answers[i] = null;
      }
      _idx = 0;
      _done = false;
    });
  }

  Future<void> _runFollowUp() async {
    final areas = _problemAreas;
    final cat = _categoryForAreas(areas);
    final plan = ExerciseLibrary.buildQuickPlan(cat, targetSeconds: 180);
    final completed = await Navigator.of(context).push<bool>(
      FadeThroughRoute(
        builder: (_) =>
            SessionScreen(plan: plan, storage: widget.storage),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(completed == true);
  }

  ExerciseCategory _categoryForAreas(List<BodyArea> areas) {
    if (areas.isEmpty) return ExerciseCategory.stretch;
    final mobilityHits = areas.where((a) =>
        a == BodyArea.back ||
        a == BodyArea.shoulders ||
        a == BodyArea.neck ||
        a == BodyArea.hips).length;
    return mobilityHits >= (areas.length / 2)
        ? ExerciseCategory.mobility
        : ExerciseCategory.stretch;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posture check'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _done ? _buildResult() : _buildQuestion(),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final scheme = Theme.of(context).colorScheme;
    final q = _questions[_idx];
    final progress = (_idx + 1) / _questions.length;

    return Padding(
      key: ValueKey('q$_idx'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 320),
              builder: (_, val, _) => LinearProgressIndicator(
                value: val,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(scheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Question ${_idx + 1} of ${_questions.length}',
              style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  fontSize: 11),
            ),
          ),
          const Spacer(),
          Text(q.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(q.prompt,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(q.hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant, height: 1.4)),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: scheme.outline),
                  ),
                  onPressed: () => _answer(false),
                  child: const Text('No',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _answer(true),
                  child: const Text('Yes',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final scheme = Theme.of(context).colorScheme;
    final score = _score;
    final areas = _problemAreas;
    final tier = _resultTier(score);

    return Padding(
      key: const ValueKey('result'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: tier.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: score / 100),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, val, _) => CircularProgressIndicator(
                            value: val,
                            strokeWidth: 9,
                            backgroundColor: Colors.white24,
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                      Text('$score',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              height: 1)),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tier.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(tier.tagline,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (areas.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Spots to address',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in areas)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(a.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(a.label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        'Spotless setup. A short mobility flow keeps you there.',
                        style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(
                  areas.isEmpty ? 'Start a 3-min flow' : 'Fix it · 3 min',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _runFollowUp,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _restart,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Re-check'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _ResultTier _resultTier(int score) {
    if (score >= 80) {
      return const _ResultTier(
        label: 'Aligned',
        tagline: 'Posture is on point. Keep it loose with one short flow.',
        gradient: [Color(0xFF2EB872), Color(0xFF1B8B58)],
      );
    }
    if (score >= 60) {
      return const _ResultTier(
        label: 'Mostly good',
        tagline: 'A couple of cues to address — minutes well spent.',
        gradient: [Color(0xFFFFB74D), Color(0xFFFF8A3A)],
      );
    }
    if (score >= 40) {
      return const _ResultTier(
        label: 'Needs a reset',
        tagline: 'Several patterns to retrain. Start with the suggested flow.',
        gradient: [Color(0xFFEF6C00), Color(0xFFD84315)],
      );
    }
    return const _ResultTier(
      label: 'Reset time',
      tagline: 'Posture has drifted — a 3-minute flow recalibrates fast.',
      gradient: [Color(0xFFE53935), Color(0xFFB71C1C)],
    );
  }
}

class _ResultTier {
  final String label;
  final String tagline;
  final List<Color> gradient;
  const _ResultTier({
    required this.label,
    required this.tagline,
    required this.gradient,
  });
}
