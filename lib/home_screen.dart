import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'breathing_screen.dart';
import 'custom_builder.dart';
import 'daily_challenge.dart';
import 'daily_mantra.dart';
import 'exercise_library.dart';
import 'eye_break_screen.dart';
import 'focus_screen.dart';
import 'models.dart';
import 'posture_check_screen.dart';
import 'walk_break_screen.dart';
import 'recommendations.dart';
import 'session_screen.dart';
import 'smart_coach.dart';
import 'storage.dart';
import 'transitions.dart';
import 'wellness_detail_screen.dart';
import 'wellness_score.dart';

class HomeScreen extends StatelessWidget {
  final Storage storage;
  final VoidCallback onSessionComplete;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.onSessionComplete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final recommendation = Recommender.pick(storage, now: now);
    final recommended = recommendation.plan;
    final greeting = _greeting(now.hour);
    final streak = storage.currentStreak;
    final freezes = storage.freezesAvailable;
    final todayMin = storage.todayMinutes;
    final goal = storage.dailyGoalMinutes;
    final score = WellnessScore.compute(storage, now: now);
    final todaySessions =
        DailyChallengeService.sessionsForToday(storage.sessions, now);
    final challenge = DailyChallengeService.forDate(now,
        dailyGoalMinutes: storage.dailyGoalMinutes);
    final coachLines = SmartCoach.dailySummary(storage, now: now);
    final mantra = DailyMantra.forDate(now, profile: storage.profile);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _Header(greeting: greeting, streak: streak, freezes: freezes),
            const SizedBox(height: 14),
            _StreakRescueBanner(
              storage: storage,
              now: now,
              onRescue: () {
                final plan = ExerciseLibrary.buildQuickPlan(
                  ExerciseCategory.mobility,
                  targetSeconds: 120,
                );
                _startPlan(context, plan);
              },
            ),
            _SitTimerPill(
              storage: storage,
              now: now,
              onQuickStart: () {
                final plan = ExerciseLibrary.buildQuickPlan(
                  ExerciseCategory.mobility,
                  targetSeconds: 120,
                );
                _startPlan(context, plan);
              },
            ),
            const SizedBox(height: 10),
            _HydrationPill(
              storage: storage,
              onChanged: onSessionComplete,
            ),
            const SizedBox(height: 10),
            _EnergyPill(
              storage: storage,
              onChanged: onSessionComplete,
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(FadeThroughRoute(
                  builder: (_) => WellnessDetailScreen(score: score),
                ));
              },
              child: _WellnessScoreCard(
                  score: score, todayMinutes: todayMin, goalMinutes: goal),
            ),
            const SizedBox(height: 20),
            _SmartCoachCard(lines: coachLines),
            const SizedBox(height: 14),
            _DailyMantraCard(mantra: mantra),
            const SizedBox(height: 20),
            Text('Recommended now',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _RecommendedCard(
              plan: recommended,
              reason: recommendation.reason,
              onStart: () => _startPlan(context, recommended),
            ),
            const SizedBox(height: 16),
            _DailyChallengeCard(
              challenge: challenge,
              todaySessions: todaySessions,
              onStart: () {
                final plan = _planForChallenge(challenge);
                if (plan != null) _startPlan(context, plan);
              },
            ),
            const SizedBox(height: 24),
            Text('Daily rituals',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _RitualsRow(
              onTap: (idx) =>
                  _startPlan(context, ExerciseLibrary.featuredPlans[idx]),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            Text('Wellness tools',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _WellnessToolsRow(
              eyeBreaksToday: storage.eyeBreaksToday,
              postureScore: storage.latestPostureScore,
              onEyeBreak: () async {
                final ok = await Navigator.of(context).push<bool>(
                  FadeThroughRoute(
                    builder: (_) => EyeBreakScreen(storage: storage),
                  ),
                );
                if (ok == true) onSessionComplete();
              },
              onWalkBreak: () async {
                final ok = await Navigator.of(context).push<bool>(
                  FadeThroughRoute(
                    builder: (_) => WalkBreakScreen(storage: storage),
                  ),
                );
                if (ok == true) onSessionComplete();
              },
              onPostureCheck: () async {
                final ok = await Navigator.of(context).push<bool>(
                  FadeThroughRoute(
                    builder: (_) => PostureCheckScreen(storage: storage),
                  ),
                );
                if (ok == true) onSessionComplete();
                onSessionComplete();
              },
            ),
            const SizedBox(height: 24),
            Text('Categories',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _CategoryGrid(
              onTap: (cat) {
                final plan = ExerciseLibrary.buildQuickPlan(cat);
                _startPlan(context, plan);
              },
            ),
            const SizedBox(height: 24),
            Text('Featured plans',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...ExerciseLibrary.featuredPlans.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PlanTile(
                  plan: p,
                  onTap: () => _startPlan(context, p),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  WorkoutPlan? _planForChallenge(DailyChallenge c) {
    switch (c.kind) {
      case ChallengeKind.categoryMinutes:
        return ExerciseLibrary.buildQuickPlan(c.category!,
            targetSeconds: (c.minutes ?? 3) * 60);
      case ChallengeKind.variety:
        return ExerciseLibrary.featuredPlans[1]; // Energy boost mixes cats
      case ChallengeKind.totalSessions:
      case ChallengeKind.hitDailyGoal:
      case ChallengeKind.earlySession:
        return ExerciseLibrary.featuredPlans[0]; // Desk reset
    }
  }

  Future<void> _startPlan(BuildContext context, WorkoutPlan plan) async {
    final completed = await Navigator.of(context).push<bool>(
      FadeThroughRoute(
        builder: (_) => SessionScreen(plan: plan, storage: storage),
      ),
    );
    if (completed == true) {
      onSessionComplete();
    }
  }

  String _greeting(int hour) {
    if (hour < 11) return 'Good morning';
    if (hour < 17) return 'Hello';
    if (hour < 22) return 'Good evening';
    return 'Late hours';
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final int streak;
  final int freezes;
  const _Header(
      {required this.greeting, required this.streak, required this.freezes});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.bolt, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500)),
              Text('MoveMate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, height: 1.1)),
            ],
          ),
        ),
        if (freezes > 0)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Tooltip(
              message:
                  '$freezes streak freeze${freezes == 1 ? "" : "s"} — automatically protects a missed day.',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('❄️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text('$freezes',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0369A1))),
                  ],
                ),
              ),
            ),
          ),
        if (streak > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1D6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('$streak ${streak == 1 ? "day" : "days"}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB76E00))),
              ],
            ),
          ),
      ],
    );
  }

}

class _WellnessScoreCard extends StatelessWidget {
  final WellnessScore score;
  final int todayMinutes;
  final int goalMinutes;
  const _WellnessScoreCard({
    required this.score,
    required this.todayMinutes,
    required this.goalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = (score.total / 100).clamp(0.0, 1.0);
    final delta = score.delta;
    final trendColor = delta > 0
        ? const Color(0xFFB8F4D6)
        : delta < 0
            ? const Color(0xFFFFC9C9)
            : Colors.white70;
    final trendIcon = delta > 0
        ? Icons.trending_up
        : delta < 0
            ? Icons.trending_down
            : Icons.trending_flat;
    final trendText = delta == 0
        ? 'Steady vs last week'
        : '${delta > 0 ? '+' : ''}$delta vs last week';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                        tween: Tween(begin: 0.0, end: ratio),
                        duration: const Duration(milliseconds: 900),
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${score.total}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1)),
                        const Text('score',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Wellness score',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(score.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(trendIcon, size: 14, color: trendColor),
                          const SizedBox(width: 4),
                          Text(trendText,
                              style: TextStyle(
                                  color: trendColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ScorePill(
                  label: 'Streak', value: score.streakComponent),
              const SizedBox(width: 8),
              _ScorePill(
                  label: 'Variety', value: score.varietyComponent),
              const SizedBox(width: 8),
              _ScorePill(
                  label: 'Volume', value: score.volumeComponent),
              const SizedBox(width: 8),
              _ScorePill(label: 'Today', value: score.todayComponent),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              goalMinutes == 0
                  ? 'Set a daily goal in Settings.'
                  : todayMinutes >= goalMinutes
                      ? 'Daily goal reached — keep the streak!'
                      : '$todayMinutes / $goalMinutes min today.',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final int value;
  const _ScorePill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final WorkoutPlan plan;
  final String reason;
  final VoidCallback onStart;
  const _RecommendedCard(
      {required this.plan, required this.reason, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final accent = plan.primaryCategory.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onStart,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(plan.primaryCategory.icon,
                        color: accent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(plan.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(plan.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Chip(
                                label: plan.formattedDuration,
                                icon: Icons.timer_outlined),
                            _Chip(
                                label: '${plan.exercises.length} exercises',
                                icon: Icons.format_list_numbered),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                    ),
                    child: const Text('Start'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(reason,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SmartCoachCard extends StatelessWidget {
  final List<CoachLine> lines;
  const _SmartCoachCard({required this.lines});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            scheme.surfaceContainerHigh,
            scheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.25),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Smart Coach',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('today',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < lines.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1, right: 8),
                    child: Text(lines[i].emoji,
                        style: const TextStyle(fontSize: 16)),
                  ),
                  Expanded(
                    child: Text(lines[i].text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                            height: 1.35,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final List<SessionRecord> todaySessions;
  final VoidCallback onStart;
  const _DailyChallengeCard({
    required this.challenge,
    required this.todaySessions,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = challenge.progressFor(todaySessions);
    final done = progress >= 1.0;
    final progressLabel = challenge.progressLabelFor(todaySessions);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: done ? null : onStart,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: done
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: done ? scheme.primary : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: done
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 22)
                          : Text(challenge.emoji,
                              style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text('Today\'s challenge',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6)),
                            if (done) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('DONE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    )),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(challenge.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  if (!done)
                    Icon(Icons.arrow_forward,
                        color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 700),
                  builder: (_, val, _) => LinearProgressIndicator(
                    value: val,
                    minHeight: 7,
                    backgroundColor:
                        scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(challenge.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.3)),
                  ),
                  const SizedBox(width: 10),
                  Text(progressLabel,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }
}

class _FocusModeTile extends StatelessWidget {
  final VoidCallback onTap;
  const _FocusModeTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
      ),
    );
  }
}

class _BreathingTile extends StatelessWidget {
  final VoidCallback onTap;
  const _BreathingTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
      ),
    );
  }
}

class _SitTimerPill extends StatelessWidget {
  final Storage storage;
  final DateTime now;
  final VoidCallback onQuickStart;
  const _SitTimerPill({
    required this.storage,
    required this.now,
    required this.onQuickStart,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = storage.sessions;
    if (sessions.isEmpty) return const SizedBox.shrink();
    final last = sessions.first.completedAt;
    final diff = now.difference(last);
    final reminderHours = storage.reminderIntervalHours;

    final ratio = diff.inMinutes / (reminderHours * 60);
    final Color accent;
    final IconData icon;
    final String headline;
    if (ratio < 0.85) {
      accent = const Color(0xFF2EB872);
      icon = Icons.check_circle_outline;
      headline = 'You\'re on rhythm';
    } else if (ratio < 1.6) {
      accent = const Color(0xFFFFA726);
      icon = Icons.access_time;
      headline = 'Time to move soon';
    } else {
      accent = const Color(0xFFE53935);
      icon = Icons.warning_amber_outlined;
      headline = 'You\'ve been still too long';
    }

    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final ago = h > 0 ? '${h}h ${m}m' : '${m}m';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: ratio < 0.85 ? null : onQuickStart,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: accent.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: accent)),
                    Text('Last move $ago ago',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              if (ratio >= 0.85)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onQuickStart,
                  child: const Text('Quick 2 min',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HydrationPill extends StatelessWidget {
  final Storage storage;
  final VoidCallback onChanged;
  const _HydrationPill({required this.storage, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final glasses = storage.glassesToday;
    final goal = storage.hydrationGoalGlasses;
    final ratio = goal == 0 ? 0.0 : (glasses / goal).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    const blue = Color(0xFF1E88E5);
    final hit = glasses >= goal;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: blue.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          const Text('💧', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                        hit
                            ? 'Hydration goal hit!'
                            : '$glasses / $goal glasses',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: scheme.onSurface)),
                    if (hit) ...[
                      const SizedBox(width: 6),
                      const Text('✅', style: TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: blue.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(blue),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 22),
            color: blue,
            tooltip: 'Remove glass',
            visualDensity: VisualDensity.compact,
            onPressed: glasses > 0
                ? () async {
                    await storage.removeGlass();
                    HapticFeedback.selectionClick();
                    onChanged();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, size: 28),
            color: blue,
            tooltip: 'Add glass',
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await storage.addGlass();
              HapticFeedback.lightImpact();
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

class _StreakRescueBanner extends StatelessWidget {
  final Storage storage;
  final DateTime now;
  final VoidCallback onRescue;
  const _StreakRescueBanner({
    required this.storage,
    required this.now,
    required this.onRescue,
  });

  @override
  Widget build(BuildContext context) {
    final streak = storage.currentStreak;
    if (streak <= 0) return const SizedBox.shrink();
    if (storage.todayMinutes > 0) return const SizedBox.shrink();
    if (storage.freezesAvailable > 0) return const SizedBox.shrink();
    final hour = now.hour;
    if (hour < 17) return const SizedBox.shrink();

    final hoursLeft = 24 - hour;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onRescue,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Text('🆘', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Save your streak',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        '$streak-day streak ends in ${hoursLeft}h. 2 minutes of mobility keeps it alive.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Rescue',
                      style: TextStyle(
                          color: Color(0xFFC62828),
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyMantraCard extends StatelessWidget {
  final Mantra mantra;
  const _DailyMantraCard({required this.mantra});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            scheme.tertiaryContainer,
            scheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Text(mantra.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Today\'s mantra',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: scheme.onPrimaryContainer
                            .withValues(alpha: 0.75))),
                const SizedBox(height: 2),
                Text(mantra.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: scheme.onPrimaryContainer)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyPill extends StatelessWidget {
  final Storage storage;
  final VoidCallback onChanged;
  const _EnergyPill({required this.storage, required this.onChanged});

  static const _emojis = ['😴', '😕', '😐', '🙂', '⚡'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = _todayEnergy();
    const accent = Color(0xFFFFB74D);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    today == null
                        ? 'How\'s your energy?'
                        : 'Energy logged: ${_emojis[today - 1]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: scheme.onSurface)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (int i = 0; i < _emojis.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _EnergyDot(
                          emoji: _emojis[i],
                          selected: today == i + 1,
                          onTap: () async {
                            await storage.logEnergy(i + 1);
                            HapticFeedback.selectionClick();
                            onChanged();
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int? _todayEnergy() {
    final log = storage.energyLog;
    final now = DateTime.now();
    final key =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final today = log[key];
    return (today == null || today.isEmpty) ? null : today.last;
  }
}

class _EnergyDot extends StatelessWidget {
  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  const _EnergyDot({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFB74D);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.4,
            ),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

class _WellnessToolsRow extends StatelessWidget {
  final int eyeBreaksToday;
  final int? postureScore;
  final VoidCallback onEyeBreak;
  final VoidCallback onWalkBreak;
  final VoidCallback onPostureCheck;
  const _WellnessToolsRow({
    required this.eyeBreaksToday,
    required this.postureScore,
    required this.onEyeBreak,
    required this.onWalkBreak,
    required this.onPostureCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToolCard(
            onTap: onEyeBreak,
            emoji: '👀',
            title: 'Eye',
            subtitle: '20-20-20',
            badge: eyeBreaksToday > 0 ? '$eyeBreaksToday today' : '30s',
            gradient: const [Color(0xFF3D5A80), Color(0xFF293E66)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToolCard(
            onTap: onWalkBreak,
            emoji: '🚶',
            title: 'Walk',
            subtitle: '1 / 2 / 5 min',
            badge: 'Cardio',
            gradient: const [Color(0xFFE57373), Color(0xFFD84315)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToolCard(
            onTap: onPostureCheck,
            emoji: '🧍',
            title: 'Posture',
            subtitle: '5-step check',
            badge: postureScore != null ? '$postureScore / 100' : 'Run',
            gradient: const [Color(0xFF7B5CFF), Color(0xFF4A6CFF)],
          ),
        ),
      ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
      ),
    );
  }
}
