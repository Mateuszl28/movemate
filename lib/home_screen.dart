import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'adaptive_plan.dart';
import 'moment_of_pride.dart';
import 'animated_widgets.dart';
import 'daily_challenge.dart';
import 'daily_mantra.dart';
import 'exercise_library.dart';
import 'models.dart';
import 'recommendations.dart';
import 'session_screen.dart';
import 'smart_coach.dart';
import 'storage.dart';
import 'tools_screen.dart' show PressableCard;
import 'transitions.dart';
import 'weekly_plan_screen.dart';
import 'wellness_detail_screen.dart';
import 'wellness_score.dart';

/// Home is the daily dashboard — signals, recommendations, and what's pending.
/// Anything action-oriented (categories, plans, builders, tools) lives in the
/// Tools tab. The CTA at the bottom hands off to it.
class HomeScreen extends StatelessWidget {
  final Storage storage;
  final VoidCallback onSessionComplete;
  final VoidCallback onOpenTools;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.onSessionComplete,
    required this.onOpenTools,
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
    final plan = AdaptivePlan.build(storage, from: now);
    final today = plan.days.first;
    final pride = MomentOfPride.compute(storage, now: now);

    final cards = <Widget>[
      _Header(
          greeting: greeting,
          dateLabel: _dateLabel(now),
          streak: streak,
          freezes: freezes,
          todayMinutes: todayMin,
          goalMinutes: goal),
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
      _TodayCard(
        storage: storage,
        now: now,
        onChanged: onSessionComplete,
        onQuickStart: () {
          final plan = ExerciseLibrary.buildQuickPlan(
            ExerciseCategory.mobility,
            targetSeconds: 120,
          );
          _startPlan(context, plan);
        },
      ),
      PressableCard(
        borderRadius: 24,
        onTap: () {
          Navigator.of(context).push(FadeThroughRoute(
            builder: (_) => WellnessDetailScreen(score: score),
          ));
        },
        child: _WellnessScoreCard(
            score: score, todayMinutes: todayMin, goalMinutes: goal),
      ),
      if (pride != null) _MomentOfPrideCard(pride: pride),
      _SmartCoachCard(lines: coachLines, mantra: mantra),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'Today\'s plan · ${today.theme}',
            hint: 'Day 1 of your adaptive 7-day plan.',
          ),
          const SizedBox(height: 12),
          _PlanDayCard(
            day: today,
            onStart: () => _startPlan(context, today.plan),
            onSeeAll: () {
              Navigator.of(context).push(FadeThroughRoute(
                builder: (_) => WeeklyPlanScreen(storage: storage),
              ));
            },
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            title: 'Recommended now',
            hint: 'Tuned to your time, mood, and history.',
          ),
          const SizedBox(height: 12),
          _RecommendedCard(
            plan: recommended,
            reason: recommendation.reason,
            onStart: () => _startPlan(context, recommended),
          ),
        ],
      ),
      _DailyChallengeCard(
        challenge: challenge,
        todaySessions: todaySessions,
        onStart: () {
          final plan = _planForChallenge(challenge);
          if (plan != null) _startPlan(context, plan);
        },
      ),
      _BrowseAllToolsCard(onTap: onOpenTools),
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
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (_, i) =>
                StaggeredFadeIn(index: i, child: cards[i]),
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) {
    return DateFormat('EEEE · d MMM', 'en_US').format(d);
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
  final String dateLabel;
  final int streak;
  final int freezes;
  final int todayMinutes;
  final int goalMinutes;
  const _Header({
    required this.greeting,
    required this.dateLabel,
    required this.streak,
    required this.freezes,
    required this.todayMinutes,
    required this.goalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = goalMinutes <= 0
        ? 0.0
        : (todayMinutes / goalMinutes).clamp(0.0, 1.0);
    final hitGoal = todayMinutes >= goalMinutes;
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, t, _) => SizedBox(
            width: 52,
            height: 52,
            child: CustomPaint(
              painter: _GoalRingPainter(
                progress: t,
                trackColor:
                    scheme.outline.withValues(alpha: 0.18),
                fillColor: hitGoal
                    ? const Color(0xFF50C878)
                    : scheme.primary,
                glow: hitGoal,
              ),
              child: Center(
                child: hitGoal
                    ? const Icon(Icons.check_rounded,
                        color: Color(0xFF2EB872), size: 26)
                    : Text('${(t * 100).round()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: scheme.primary,
                        )),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(greeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: scheme.outline.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(dateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4)),
                  ),
                ],
              ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String hint;
  const _SectionTitle({required this.title, required this.hint});

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

/// Combines the three quick-stat slots — last-move timer, hydration, energy
/// check-in — into a single dashboard card. Replaces the old separate pills
/// to cut visual noise.
class _TodayCard extends StatelessWidget {
  final Storage storage;
  final DateTime now;
  final VoidCallback onChanged;
  final VoidCallback onQuickStart;
  const _TodayCard({
    required this.storage,
    required this.now,
    required this.onChanged,
    required this.onQuickStart,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _SitRow(
              storage: storage, now: now, onQuickStart: onQuickStart),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          _HydrationRow(storage: storage, onChanged: onChanged),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          _EnergyRow(storage: storage, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SitRow extends StatelessWidget {
  final Storage storage;
  final DateTime now;
  final VoidCallback onQuickStart;
  const _SitRow({
    required this.storage,
    required this.now,
    required this.onQuickStart,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = storage.sessions;
    final scheme = Theme.of(context).colorScheme;
    if (sessions.isEmpty) {
      return Row(
        children: [
          const _RowIcon(emoji: '⏱️', color: Color(0xFF2EB872)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No sessions yet',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface)),
                Text('Tap below to start your first one.',
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onQuickStart,
            child: const Text('Start',
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      );
    }
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
      headline = 'On rhythm';
    } else if (ratio < 1.6) {
      accent = const Color(0xFFFFA726);
      icon = Icons.access_time;
      headline = 'Move soon';
    } else {
      accent = const Color(0xFFE53935);
      icon = Icons.warning_amber_outlined;
      headline = 'Still too long';
    }
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final ago = h > 0 ? '${h}h ${m}m' : '${m}m';

    return Row(
      children: [
        _RowIcon(icon: icon, color: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(headline,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: accent)),
              Text('Last move $ago ago',
                  style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant)),
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
                style:
                    TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
      ],
    );
  }
}

class _HydrationRow extends StatelessWidget {
  final Storage storage;
  final VoidCallback onChanged;
  const _HydrationRow({required this.storage, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final glasses = storage.glassesToday;
    final goal = storage.hydrationGoalGlasses;
    final ratio = goal == 0 ? 0.0 : (glasses / goal).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    const blue = Color(0xFF1E88E5);
    final hit = glasses >= goal;

    return Row(
      children: [
        const _RowIcon(emoji: '💧', color: blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  hit
                      ? 'Hydration goal hit'
                      : 'Hydration · $glasses / $goal',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: blue.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
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
    );
  }
}

class _EnergyRow extends StatelessWidget {
  final Storage storage;
  final VoidCallback onChanged;
  const _EnergyRow({required this.storage, required this.onChanged});

  static const _emojis = ['😴', '😕', '😐', '🙂', '⚡'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = _todayEnergy();
    const accent = Color(0xFFFFB74D);

    return Row(
      children: [
        const _RowIcon(emoji: '⚡', color: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  today == null
                      ? 'How\'s your energy?'
                      : 'Energy · ${_emojis[today - 1]} logged',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface)),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (int i = 0; i < _emojis.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
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
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.32)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? accent : Colors.transparent,
              width: 1.4,
            ),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final Color color;
  const _RowIcon({this.emoji, this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: const TextStyle(fontSize: 18))
          : Icon(icon, color: color, size: 20),
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
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
    return PressableCard(
      borderRadius: 24,
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: accent.withValues(alpha: 0.4), width: 1.4),
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

/// Celebration hero — picks the best stat from recent activity and surfaces it
/// as a gradient card so the user sees their wins, not just their nags.
class _MomentOfPrideCard extends StatelessWidget {
  final MomentOfPride pride;
  const _MomentOfPrideCard({required this.pride});

  @override
  Widget build(BuildContext context) {
    final colors = _gradientFor(pride.kind);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(pride.emoji,
                      style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Moment of pride',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          )),
                      const SizedBox(height: 2),
                      Text(pride.headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          )),
                      const SizedBox(height: 4),
                      Text(pride.subline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<Color> _gradientFor(PrideKind kind) {
    switch (kind) {
      case PrideKind.painDrop:
        return const [Color(0xFFFF6F61), Color(0xFFD84315)];
      case PrideKind.streak:
        return const [Color(0xFFFFB300), Color(0xFFFF6F00)];
      case PrideKind.weekGrowth:
        return const [Color(0xFF42A5F5), Color(0xFF1E88E5)];
      case PrideKind.milestone:
        return const [Color(0xFF7C4DFF), Color(0xFF512DA8)];
      case PrideKind.moodLift:
        return const [Color(0xFFAB47BC), Color(0xFF7B1FA2)];
      case PrideKind.variety:
        return const [Color(0xFF26A69A), Color(0xFF00897B)];
      case PrideKind.comeback:
        return const [Color(0xFF66BB6A), Color(0xFF388E3C)];
    }
  }
}

/// Coach lines + the day's mantra collapsed into one card. Mantra is rendered
/// as a slim header strip; coach lines fill the body.
class _SmartCoachCard extends StatelessWidget {
  final List<CoachLine> lines;
  final Mantra mantra;
  const _SmartCoachCard({required this.lines, required this.mantra});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
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
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
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
                Text(mantra.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(mantra.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: scheme.onPrimaryContainer)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 10),
                    Text('Smart Coach',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('today',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: scheme.onSurface,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
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
    return PressableCard(
      borderRadius: 20,
      onTap: done ? () {} : onStart,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: done ? scheme.primaryContainer : scheme.surfaceContainerHigh,
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
      child: PressableCard(
        borderRadius: 20,
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
    );
  }
}

class _PlanDayCard extends StatelessWidget {
  final AdaptiveDay day;
  final VoidCallback onStart;
  final VoidCallback onSeeAll;
  const _PlanDayCard({
    required this.day,
    required this.onStart,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = day.plan.primaryCategory.accent;
    return PressableCard(
      borderRadius: 22,
      onTap: onStart,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(day.plan.primaryCategory.icon,
                      color: accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('TODAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                )),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(day.theme,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(day.plan.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(day.reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.3)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(day.plan.formattedDuration,
                      style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onStart,
                    child: const Text('Start today',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_view_week, size: 18),
                  label: const Text('See week'),
                  onPressed: onSeeAll,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseAllToolsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BrowseAllToolsCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableCard(
      onTap: onTap,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: scheme.primaryContainer,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.dashboard_customize,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Browse all tools',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: scheme.onPrimaryContainer)),
                  const SizedBox(height: 2),
                  Text(
                      'Daily rituals, eye / walk / posture breaks, builder, breath, focus, categories.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: scheme.onPrimaryContainer
                              .withValues(alpha: 0.85))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward,
                color: scheme.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}
