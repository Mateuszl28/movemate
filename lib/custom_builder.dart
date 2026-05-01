import 'package:flutter/material.dart';

import 'exercise_library.dart';
import 'models.dart';

/// Bottom sheet that lets the user pick a duration and a set of categories.
/// Returns a generated [WorkoutPlan] or null if dismissed.
Future<WorkoutPlan?> showCustomBuilder(BuildContext context) {
  return showModalBottomSheet<WorkoutPlan>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _CustomBuilderSheet(),
  );
}

class _CustomBuilderSheet extends StatefulWidget {
  const _CustomBuilderSheet();

  @override
  State<_CustomBuilderSheet> createState() => _CustomBuilderSheetState();
}

class _CustomBuilderSheetState extends State<_CustomBuilderSheet> {
  int _minutes = 3;
  final Set<ExerciseCategory> _selected = {
    ExerciseCategory.stretch,
    ExerciseCategory.mobility,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canGenerate = _selected.isNotEmpty;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: scheme.primary),
              const SizedBox(width: 10),
              Text('Build your own',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Pick a length and the categories you want.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant)),
          const SizedBox(height: 18),
          Text('Duration: $_minutes min',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Slider(
            value: _minutes.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            label: '$_minutes min',
            onChanged: (v) => setState(() => _minutes = v.round()),
          ),
          const SizedBox(height: 8),
          Text('Categories',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final cat in ExerciseCategory.values)
                _CategoryChip(
                  category: cat,
                  selected: _selected.contains(cat),
                  onTap: () => setState(() {
                    if (_selected.contains(cat)) {
                      _selected.remove(cat);
                    } else {
                      _selected.add(cat);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: canGenerate
                  ? () {
                      final plan = _generatePlan();
                      Navigator.of(context).pop(plan);
                    }
                  : null,
              child: const Text('Generate session',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  WorkoutPlan _generatePlan() {
    final cats = _selected.toList();
    final pools = {
      for (final c in cats) c: ExerciseLibrary.byCategory(c).toList(),
    };
    final indices = {for (final c in cats) c: 0};

    final target = _minutes * 60;
    int total = 0;
    final picks = <Exercise>[];

    // Round-robin across selected categories until we hit the target.
    int turn = 0;
    while (total < target && picks.length < 12) {
      final cat = cats[turn % cats.length];
      final pool = pools[cat]!;
      if (pool.isEmpty) {
        turn++;
        continue;
      }
      final idx = indices[cat]!;
      final ex = pool[idx % pool.length];
      picks.add(ex);
      indices[cat] = idx + 1;
      total += ex.seconds;
      turn++;
    }

    final primary = cats.first;
    final ceilMin = (total / 60).ceil();
    return WorkoutPlan(
      title: 'Custom session',
      subtitle:
          '$ceilMin min — ${cats.map((c) => c.label.toLowerCase()).join(' + ')}',
      primaryCategory: primary,
      exercises: picks,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ExerciseCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.category,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = category.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.20)
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(category.icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(category.label,
                  style: TextStyle(
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
              const SizedBox(width: 6),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                size: 18,
                color: selected
                    ? accent
                    : Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
