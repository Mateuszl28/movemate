import 'package:flutter/material.dart';

import 'animated_widgets.dart';
import 'breathing_screen.dart';
import 'custom_builder.dart';
import 'exercise_library.dart';
import 'eye_break_screen.dart';
import 'focus_screen.dart';
import 'mindful_screen.dart';
import 'models.dart';
import 'pain_journal_screen.dart';
import 'posture_check_screen.dart';
import 'session_screen.dart';
import 'sleep_screen.dart';
import 'storage.dart';
import 'tension_screen.dart';
import 'transitions.dart';
import 'walk_break_screen.dart';
import 'weekly_plan_screen.dart';

/// All the "what can I do right now?" surfaces — wellness tools, daily
/// rituals, builders, categories, plans. Pulled off the Home dashboard so the
/// dashboard can focus on signals and recommendations.
class ToolsScreen extends StatelessWidget {
  final Storage storage;
  final VoidCallback onSessionComplete;

  const ToolsScreen({
    super.key,
    required this.storage,
    required this.onSessionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final sections = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tools',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              'Pick a quick reset, a guided ritual, or build your own session.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant)),
        ],
      ),
      _AdaptivePlanCard(
        onTap: () =>
            _push(context, WeeklyPlanScreen(storage: storage)),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Wellness tools',
            hint: 'Micro-breaks for body, mind, and rest.',
          ),
          const SizedBox(height: 12),
          _WellnessToolsRow(
            eyeBreaksToday: storage.eyeBreaksToday,
            postureScore: storage.latestPostureScore,
            mindfulToday: storage.mindfulToday,
            latestSleepHours: storage.latestSleep?.hours,
            painCount: storage.painToday.length,
            onEyeBreak: () =>
                _push(context, EyeBreakScreen(storage: storage)),
            onWalkBreak: () =>
                _push(context, WalkBreakScreen(storage: storage)),
            onPostureCheck: () =>
                _push(context, PostureCheckScreen(storage: storage)),
            onTensionMap: () =>
                _push(context, TensionScreen(storage: storage)),
            onMindful: () =>
                _push(context, MindfulScreen(storage: storage)),
            onSleep: () => _push(context, SleepScreen(storage: storage)),
            onPainJournal: () =>
                _push(context, PainJournalScreen(storage: storage)),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Daily rituals',
            hint: 'A flow tuned to your time of day.',
          ),
          const SizedBox(height: 12),
          _RitualsRow(
            onTap: (idx) =>
                _startPlan(context, ExerciseLibrary.featuredPlans[idx]),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Quick starts',
            hint: 'Custom mix, focus block, or guided breath.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BuildYourOwnTile(
                  onTap: () async {
                    final plan = await showCustomBuilder(context);
                    if (plan != null && context.mounted) {
                      await _startPlan(context, plan);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FocusModeTile(
                  onTap: () {
                    Navigator.of(context).push(FadeThroughRoute(
                      builder: (_) => FocusScreen(storage: storage),
                    ));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BreathingTile(
                  onTap: () async {
                    final logged = await Navigator.of(context).push<bool>(
                      FadeThroughRoute(
                        builder: (_) =>
                            BreathingScreen(storage: storage),
                      ),
                    );
                    if (logged == true) onSessionComplete();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Categories',
            hint: 'Browse the full library by intent.',
          ),
          const SizedBox(height: 12),
          _CategoryGrid(
            onTap: (cat) {
              final plan = ExerciseLibrary.buildQuickPlan(cat);
              _startPlan(context, plan);
            },
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Featured plans',
            hint: 'Curated combos for common moments.',
          ),
          const SizedBox(height: 12),
          for (final p in ExerciseLibrary.featuredPlans)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlanTile(
                plan: p,
                onTap: () => _startPlan(context, p),
              ),
            ),
        ],
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 250));
            onSessionComplete();
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 22),
            itemBuilder: (_, i) =>
                StaggeredFadeIn(index: i, child: sections[i]),
          ),
        ),
      ),
    );
  }

  Future<void> _push(BuildContext context, Widget screen) async {
    final ok = await Navigator.of(context).push<bool>(
      FadeThroughRoute(builder: (_) => screen),
    );
    if (ok == true) onSessionComplete();
  }

  Future<void> _startPlan(BuildContext context, WorkoutPlan plan) async {
    final completed = await Navigator.of(context).push<bool>(
      FadeThroughRoute(
        builder: (_) => SessionScreen(plan: plan, storage: storage),
      ),
    );
    if (completed == true) onSessionComplete();
  }
}

class _AdaptivePlanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AdaptivePlanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableCard(
      onTap: onTap,
      borderRadius: 22,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🗓️', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Adaptive 7-day plan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.1)),
                  const SizedBox(height: 4),
                  Text(
                    'Generated from your profile, body coverage, pain, sleep, and energy.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String hint;
  const _SectionHeader({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant, height: 1.3)),
      ],
    );
  }
}

class _WellnessToolsRow extends StatelessWidget {
  final int eyeBreaksToday;
  final int? postureScore;
  final int mindfulToday;
  final double? latestSleepHours;
  final int painCount;
  final VoidCallback onEyeBreak;
  final VoidCallback onWalkBreak;
  final VoidCallback onPostureCheck;
  final VoidCallback onTensionMap;
  final VoidCallback onMindful;
  final VoidCallback onSleep;
  final VoidCallback onPainJournal;
  const _WellnessToolsRow({
    required this.eyeBreaksToday,
    required this.postureScore,
    required this.mindfulToday,
    required this.latestSleepHours,
    required this.painCount,
    required this.onEyeBreak,
    required this.onWalkBreak,
    required this.onPostureCheck,
    required this.onTensionMap,
    required this.onMindful,
    required this.onSleep,
    required this.onPainJournal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            width: 132,
            child: _ToolCard(
              onTap: onEyeBreak,
              emoji: '👀',
              title: 'Eye',
              subtitle: '20-20-20',
              badge: eyeBreaksToday > 0 ? '$eyeBreaksToday today' : '30s',
              gradient: const [Color(0xFF3D5A80), Color(0xFF293E66)],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: _ToolCard(
              onTap: onWalkBreak,
              emoji: '🚶',
              title: 'Walk',
              subtitle: '1 / 2 / 5 min',
              badge: 'Cardio',
              gradient: const [Color(0xFFE57373), Color(0xFFD84315)],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: _ToolCard(
              onTap: onPostureCheck,
              emoji: '🧍',
              title: 'Posture',
              subtitle: '5-step check',
              badge: postureScore != null ? '$postureScore / 100' : 'Run',
              gradient: const [Color(0xFF7B5CFF), Color(0xFF4A6CFF)],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: _ToolCard(
              onTap: onTensionMap,
              emoji: '🎯',
              title: 'Tension',
              subtitle: 'Pick sore spots',
              badge: 'Custom',
              gradient: const [Color(0xFF26A69A), Color(0xFF00796B)],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: _ToolCard(
              onTap: onMindful,
              emoji: '🧘',
              title: 'Mindful',
              subtitle: '5-4-3-2-1',
              badge:
                  mindfulToday > 0 ? '$mindfulToday today' : 'Ground',
              gradient: const [Color(0xFF8E24AA), Color(0xFF5E35B1)],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: _ToolCard(
              onTap: onSleep,
              emoji: '🌙',
              title: 'Sleep',
              subtitle: 'Log last night',
              badge: latestSleepHours != null
                  ? '${latestSleepHours!.toStringAsFixed(1)} h'
                  : 'New',
              gradient: const [Color(0xFF1A237E), Color(0xFF311B92)],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 132,
            child: _ToolCard(
              onTap: onPainJournal,
              emoji: '🩹',
              title: 'Pain',
              subtitle: 'Log + 14d trend',
              badge: painCount > 0 ? '$painCount today' : 'New',
              gradient: const [Color(0xFFEF6C00), Color(0xFFD84315)],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final VoidCallback onTap;
  final String emoji;
  final String title;
  final String subtitle;
  final String badge;
  final List<Color> gradient;
  const _ToolCard({
    required this.onTap,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(14),
        height: 132,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.1)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RitualsRow extends StatelessWidget {
  final void Function(int) onTap;
  const _RitualsRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rituals = const [
      _RitualSpec(
        emoji: '🌅',
        title: 'Morning',
        subtitle: 'Energy boost',
        gradient: [Color(0xFFFFB74D), Color(0xFFFF8A3A)],
        index: 1,
      ),
      _RitualSpec(
        emoji: '🌞',
        title: 'Midday',
        subtitle: 'Desk reset',
        gradient: [Color(0xFF7BC67E), Color(0xFF2EB872)],
        index: 0,
      ),
      _RitualSpec(
        emoji: '🌙',
        title: 'Evening',
        subtitle: 'Wind-down',
        gradient: [Color(0xFF7B5CFF), Color(0xFF4A6CFF)],
        index: 2,
      ),
    ];
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          for (int i = 0; i < rituals.length; i++) ...[
            Expanded(
              child: _RitualCard(
                spec: rituals[i],
                onTap: () => onTap(rituals[i].index),
              ),
            ),
            if (i < rituals.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _RitualSpec {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final int index;
  const _RitualSpec({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.index,
  });
}

class _RitualCard extends StatelessWidget {
  final _RitualSpec spec;
  final VoidCallback onTap;
  const _RitualCard({required this.spec, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      borderRadius: 18,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: spec.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: spec.gradient.last.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(spec.emoji, style: const TextStyle(fontSize: 32)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(spec.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.1)),
                Text(spec.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildYourOwnTile extends StatelessWidget {
  final VoidCallback onTap;
  const _BuildYourOwnTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableCard(
      onTap: onTap,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              scheme.secondaryContainer,
              scheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune,
                  color: Colors.white, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Build',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface)),
                Text('Custom mix',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusModeTile extends StatelessWidget {
  final VoidCallback onTap;
  const _FocusModeTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.timer_outlined,
                  color: Colors.white, size: 18),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Focus',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                Text('Pomodoro',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingTile extends StatelessWidget {
  final VoidCallback onTap;
  const _BreathingTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                  child: Text('🫁', style: TextStyle(fontSize: 18))),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Breathe',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                Text('Guided rhythm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final void Function(ExerciseCategory) onTap;
  const _CategoryGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cats = ExerciseCategory.values;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        for (final cat in cats)
          _CategoryTile(category: cat, onTap: () => onTap(cat)),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ExerciseCategory category;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = category.accent;
    return PressableCard(
      onTap: onTap,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(category.icon, color: Colors.white, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(
                  '${ExerciseLibrary.byCategory(category).length} exercises',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback onTap;
  const _PlanTile({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: onTap,
      borderRadius: 18,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: plan.primaryCategory.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(plan.primaryCategory.icon,
                  color: plan.primaryCategory.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(plan.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(plan.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// A subtle scale-on-press wrapper to add tactile feel to tap targets.
/// Renders an InkWell with a stateful scale-down animation, matching the
/// Material 3 ripple but with a tiny pop. Reusable across screens.
class PressableCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double borderRadius;
  const PressableCard({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = 16,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: widget.child,
        ),
      ),
    );
  }
}
