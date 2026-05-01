import 'dart:math';

import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

class OnboardingScreen extends StatefulWidget {
  final Storage storage;
  final VoidCallback onDone;
  const OnboardingScreen(
      {super.key, required this.storage, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  ActivityProfile _profile = ActivityProfile.sedentary;
  int _goal = 10;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bolt,
                        color: Colors.white, size: 22),
                  ),
                  if (_page < 2)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Skip'),
                    )
                  else
                    const SizedBox(width: 60),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(),
                  _HowItWorksPage(),
                  _ProfilePage(
                    profile: _profile,
                    goal: _goal,
                    onProfile: (p) => setState(() => _profile = p),
                    onGoal: (g) => setState(() => _goal = g),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color:
                        active ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (_page < 2) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                      );
                    } else {
                      _finish();
                    }
                  },
                  child: Text(_page < 2 ? 'Next' : 'Get started',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    await widget.storage.setProfile(_profile);
    await widget.storage.setDailyGoalMinutes(_goal);
    await widget.storage.setOnboarded(true);
    widget.onDone();
  }
}

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(child: _OrbitalHero(size: 240)),
          const SizedBox(height: 32),
          Text('Welcome to MoveMate',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 12),
          Text(
            'Your micro-activity coach for the desk-bound. Two minutes can change your day.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How it works',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 8),
          Text('Three things make MoveMate different.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 28),
          _AnimatedHero(
            delay: 0,
            child: const _FeatureRow(
              emoji: '🤖',
              title: 'Smart Coach',
              body: 'Adapts to your week — suggests what you\'re missing.',
            ),
          ),
          const SizedBox(height: 18),
          _AnimatedHero(
            delay: 120,
            child: const _FeatureRow(
              emoji: '😊',
              title: 'Mood tracking',
              body: 'Quick check-in before/after shows how movement feels.',
            ),
          ),
          const SizedBox(height: 18),
          _AnimatedHero(
            delay: 240,
            child: const _FeatureRow(
              emoji: '🔥',
              title: 'Streak + freezes',
              body: 'Build a daily streak — earn freezes that protect it.',
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;
  const _FeatureRow({
    required this.emoji,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  final ActivityProfile profile;
  final int goal;
  final ValueChanged<ActivityProfile> onProfile;
  final ValueChanged<int> onGoal;
  const _ProfilePage({
    required this.profile,
    required this.goal,
    required this.onProfile,
    required this.onGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: ListView(
        children: [
          Text('Personalize your coach',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 8),
          Text('Pick a profile and how many minutes you want to move daily.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 22),
          Text('Activity profile',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final p in ActivityProfile.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProfileTile(
                profile: p,
                selected: profile == p,
                onTap: () => onProfile(p),
              ),
            ),
          const SizedBox(height: 16),
          Text('Daily goal',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text('$goal minutes of movement per day',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Slider(
            value: goal.toDouble(),
            min: 5,
            max: 30,
            divisions: 5,
            label: '$goal min',
            onChanged: (v) => onGoal(v.round()),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final ActivityProfile profile;
  final bool selected;
  final VoidCallback onTap;
  const _ProfileTile(
      {required this.profile,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(profile.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
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

class _OrbitalHero extends StatefulWidget {
  final double size;
  const _OrbitalHero({this.size = 220});

  @override
  State<_OrbitalHero> createState() => _OrbitalHeroState();
}

class _OrbitalHeroState extends State<_OrbitalHero>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _pulse]),
        builder: (_, _) {
          return CustomPaint(
            painter: _OrbitalPainter(
              t: _spin.value,
              pulse: _pulse.value,
              primary: scheme.primary,
              secondary: scheme.tertiary,
              ring: scheme.outline.withValues(alpha: 0.18),
            ),
          );
        },
      ),
    );
  }
}

class _OrbitalPainter extends CustomPainter {
  final double t; // 0..1, full rotation
  final double pulse; // 0..1
  final Color primary;
  final Color secondary;
  final Color ring;

  _OrbitalPainter({
    required this.t,
    required this.pulse,
    required this.primary,
    required this.secondary,
    required this.ring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;
    final pulseEased = Curves.easeInOut.transform(pulse);

    final glowR = maxR * (0.42 + pulseEased * 0.06);
    canvas.drawCircle(
      center,
      glowR + 18,
      Paint()
        ..color = primary.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    final ringPaint = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final f in const [0.6, 0.78, 0.95]) {
      canvas.drawCircle(center, maxR * f, ringPaint);
    }

    final orbits = [
      (radius: maxR * 0.6, speed: -1.0, count: 5, color: primary, dotSize: 7.0),
      (radius: maxR * 0.78, speed: 0.65, count: 7, color: secondary, dotSize: 5.5),
      (radius: maxR * 0.95, speed: -0.4, count: 9, color: primary.withValues(alpha: 0.7), dotSize: 4.0),
    ];

    for (final o in orbits) {
      for (int i = 0; i < o.count; i++) {
        final angle =
            t * 2 * pi * o.speed + i * (2 * pi / o.count);
        final x = center.dx + cos(angle) * o.radius;
        final y = center.dy + sin(angle) * o.radius;
        canvas.drawCircle(
          Offset(x, y),
          o.dotSize,
          Paint()..color = o.color,
        );
      }
    }

    final coreGradient = Paint()
      ..shader = RadialGradient(
        colors: [
          primary,
          primary.withValues(alpha: 0.6),
          secondary.withValues(alpha: 0.6),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: glowR),
      );
    canvas.drawCircle(center, glowR, coreGradient);

    canvas.drawCircle(
      center,
      glowR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '⚡',
        style: TextStyle(fontSize: glowR * 0.85),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitalPainter old) =>
      old.t != t || old.pulse != pulse;
}

class _AnimatedHero extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AnimatedHero({required this.child, this.delay = 0});

  @override
  State<_AnimatedHero> createState() => _AnimatedHeroState();
}

class _AnimatedHeroState extends State<_AnimatedHero>
    with SingleTickerProviderStateMixin {
  double _opacity = 0;
  double _offset = 30;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (!mounted) return;
      setState(() {
        _opacity = 1;
        _offset = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      offset: Offset(0, _offset / 100),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _opacity,
        child: widget.child,
      ),
    );
  }
}
