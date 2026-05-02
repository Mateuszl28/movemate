import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'exercise_library.dart';
import 'models.dart';
import 'session_screen.dart';
import 'storage.dart';
import 'transitions.dart';

/// Tap the body areas that feel tense; we hand-pick exercises that target the
/// strongest hits and build a session from them. If nothing is selected the
/// "Build" button is disabled.
class TensionScreen extends StatefulWidget {
  final Storage storage;
  const TensionScreen({super.key, required this.storage});

  @override
  State<TensionScreen> createState() => _TensionScreenState();
}

class _TensionScreenState extends State<TensionScreen> {
  final Set<BodyArea> _picked = <BodyArea>{};

  void _toggle(BodyArea area) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_picked.add(area)) _picked.remove(area);
    });
  }

  Future<void> _buildAndStart() async {
    if (_picked.isEmpty) return;
    final plan = _planForAreas(_picked);
    final ok = await Navigator.of(context).push<bool>(
      FadeThroughRoute(
        builder: (_) => SessionScreen(plan: plan, storage: widget.storage),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(ok == true);
  }

  WorkoutPlan _planForAreas(Set<BodyArea> areas) {
    // Score every exercise by how many of the picked areas it covers.
    final scored = <_ScoredExercise>[];
    for (final ex in ExerciseLibrary.all) {
      int hits = 0;
      for (final a in ex.bodyAreas) {
        if (areas.contains(a)) hits += 1;
      }
      if (hits > 0) scored.add(_ScoredExercise(ex, hits));
    }
    scored.sort((a, b) => b.hits.compareTo(a.hits));

    final picked = <Exercise>[];
    int total = 0;
    final usedIds = <String>{};
    for (final s in scored) {
      if (usedIds.contains(s.exercise.id)) continue;
      picked.add(s.exercise);
      usedIds.add(s.exercise.id);
      total += s.exercise.seconds;
      if (picked.length >= 6 || total >= 240) break;
    }

    // Always end with a calming breath if we have room.
    if (total < 220) {
      final breath = ExerciseLibrary.all.firstWhere(
        (e) => e.category == ExerciseCategory.breath,
        orElse: () => picked.first,
      );
      if (!usedIds.contains(breath.id)) {
        picked.add(breath);
        total += breath.seconds;
      }
    }

    final primary = picked.isEmpty
        ? ExerciseCategory.stretch
        : picked.first.category;
    return WorkoutPlan(
      title: 'Tension reset',
      subtitle: '${(total / 60).ceil()} min — targeted at your sore spots',
      primaryCategory: primary,
      exercises: picked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canStart = _picked.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Where\'s the tension?'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.tertiary, scheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Build for sore spots',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1)),
                          const SizedBox(height: 4),
                          Text(
                            'Tap every area that feels tense — we\'ll prioritize exercises that hit the most overlap.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Colors.white70, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final area in BodyArea.values)
                        _AreaChip(
                          area: area,
                          selected: _picked.contains(area),
                          onTap: () => _toggle(area),
                        ),
                    ],
                  ),
                ),
              ),
              if (canStart)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                      _picked.length == 1
                          ? '1 area selected'
                          : '${_picked.length} areas selected',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Build my session',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: canStart ? _buildAndStart : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoredExercise {
  final Exercise exercise;
  final int hits;
  const _ScoredExercise(this.exercise, this.hits);
}

class _AreaChip extends StatelessWidget {
  final BodyArea area;
  final bool selected;
  final VoidCallback onTap;
  const _AreaChip({
    required this.area,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.15)
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(area.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(area.label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? scheme.primary : scheme.onSurface,
                      fontSize: 13)),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle,
                    size: 16, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
