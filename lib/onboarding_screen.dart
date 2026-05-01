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
  ActivityProfile _profile = ActivityProfile.sedentary;
  int _goal = 10;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.bolt,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 18),
              Text('Welcome to MoveMate',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                '2–5 minute micro-breaks: stretching, mobility, breathing, light cardio.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Text('Your profile',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    for (final p in ActivityProfile.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProfileTile(
                          profile: p,
                          selected: _profile == p,
                          onTap: () => setState(() => _profile = p),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text('Daily goal',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('$_goal minutes of movement per day',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Slider(
                      value: _goal.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 5,
                      label: '$_goal min',
                      onChanged: (v) => setState(() => _goal = v.round()),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    await widget.storage.setProfile(_profile);
                    await widget.storage.setDailyGoalMinutes(_goal);
                    await widget.storage.setOnboarded(true);
                    widget.onDone();
                  },
                  child: const Text('Get started',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
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
        child: Container(
          padding: const EdgeInsets.all(16),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(profile.description,
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
