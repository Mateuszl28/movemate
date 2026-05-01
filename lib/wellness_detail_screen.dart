import 'package:flutter/material.dart';

import 'wellness_score.dart';

class WellnessDetailScreen extends StatelessWidget {
  final WellnessScore score;
  const WellnessDetailScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellness score'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                              begin: 0.0,
                              end: (score.total / 100).clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, val, _) => CircularProgressIndicator(
                            value: val,
                            strokeWidth: 11,
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
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  height: 1)),
                          const Text('/ 100',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(score.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        score.delta > 0
                            ? '+${score.delta} points vs the previous week'
                            : score.delta < 0
                                ? '${score.delta} points vs the previous week'
                                : 'Steady against the previous week',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('How your score breaks down',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _ComponentTile(
            label: 'Streak',
            value: score.streakComponent,
            weight: 30,
            description:
                'Consecutive days you moved. Hits 100 at a 7-day streak.',
            tip: score.streakComponent < 50
                ? 'Aim for two short sessions in a row to build momentum.'
                : 'Use streak freezes to protect tough days.',
            color: const Color(0xFFFFB74D),
          ),
          const SizedBox(height: 10),
          _ComponentTile(
            label: 'Variety',
            value: score.varietyComponent,
            weight: 25,
            description:
                'How many of the 4 categories you used in the last 7 days.',
            tip: score.varietyComponent < 100
                ? 'Try a category you haven\'t used recently — see Smart Coach for ideas.'
                : 'You\'re using every category — beautifully balanced.',
            color: const Color(0xFF7BC67E),
          ),
          const SizedBox(height: 10),
          _ComponentTile(
            label: 'Volume',
            value: score.volumeComponent,
            weight: 30,
            description:
                'Total minutes vs. (daily goal × 7) over the last 7 days.',
            tip: score.volumeComponent < 60
                ? 'Stack a couple of 3-minute sessions to lift this fast.'
                : 'Solid weekly volume — keep stacking those minutes.',
            color: const Color(0xFF64B5F6),
          ),
          const SizedBox(height: 10),
          _ComponentTile(
            label: 'Today',
            value: score.todayComponent,
            weight: 15,
            description: 'Today\'s minutes against your daily goal.',
            tip: score.todayComponent >= 100
                ? 'Daily goal in the bag — anything more is a bonus.'
                : 'A 2-minute desk reset gets you closer right now.',
            color: const Color(0xFFE57373),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: scheme.onSurfaceVariant, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Score = Streak × 30% + Variety × 25% + Volume × 30% + Today × 15%. '
                    'Each component caps at 100. The score is a single north star, '
                    'not a verdict — focus on whichever piece is lowest today.',
                    style: Theme.of(context).textTheme.bodySmall,
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

class _ComponentTile extends StatelessWidget {
  final String label;
  final int value;
  final int weight;
  final String description;
  final String tip;
  final Color color;
  const _ComponentTile({
    required this.label,
    required this.value,
    required this.weight,
    required this.description,
    required this.tip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Text('$value',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('· $weight%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: (value / 100).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, _) => LinearProgressIndicator(
                value: val,
                minHeight: 10,
                backgroundColor: color.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant, height: 1.35)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1, right: 6),
                child: Text('💡', style: TextStyle(fontSize: 13)),
              ),
              Expanded(
                child: Text(tip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.3)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
