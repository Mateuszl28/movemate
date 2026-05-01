import 'package:flutter/material.dart';

import 'models.dart';
import 'notification_service.dart';
import 'storage.dart';
import 'tts_service.dart';

class SettingsScreen extends StatefulWidget {
  final Storage storage;
  final VoidCallback onChanged;
  const SettingsScreen(
      {super.key, required this.storage, required this.onChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ActivityProfile _profile;
  late int _reminderHours;
  late int _dailyGoal;
  late int _themeMode;
  late CoachPersonality _coach;
  late int _hydrationGoal;

  @override
  void initState() {
    super.initState();
    _profile = widget.storage.profile;
    _reminderHours = widget.storage.reminderIntervalHours;
    _dailyGoal = widget.storage.dailyGoalMinutes;
    _themeMode = widget.storage.themeModeIndex;
    _coach = CoachPersonality.values[widget.storage.coachPersonalityIndex];
    _hydrationGoal = widget.storage.hydrationGoalGlasses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Settings',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _Section(
              title: 'Activity profile',
              child: Column(
                children: [
                  for (final p in ActivityProfile.values)
                    RadioListTile<ActivityProfile>(
                      value: p,
                      groupValue: _profile,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _profile = v);
                        await widget.storage.setProfile(v);
                        widget.onChanged();
                      },
                      title: Text(p.label,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(p.description),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Daily goal',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_dailyGoal minutes of movement per day',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Slider(
                    value: _dailyGoal.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 5,
                    label: '$_dailyGoal min',
                    onChanged: (v) => setState(() => _dailyGoal = v.round()),
                    onChangeEnd: (v) async {
                      await widget.storage.setDailyGoalMinutes(v.round());
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Hydration goal',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_hydrationGoal glasses of water per day',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Slider(
                    value: _hydrationGoal.toDouble(),
                    min: 4,
                    max: 12,
                    divisions: 8,
                    label: '$_hydrationGoal',
                    onChanged: (v) =>
                        setState(() => _hydrationGoal = v.round()),
                    onChangeEnd: (v) async {
                      await widget.storage
                          .setHydrationGoalGlasses(v.round());
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Reminders',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Every $_reminderHours hour${_reminderHours == 1 ? "" : "s"} between 9 AM and 8 PM',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Slider(
                    value: _reminderHours.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    label: '$_reminderHours h',
                    onChanged: (v) =>
                        setState(() => _reminderHours = v.round()),
                    onChangeEnd: (v) async {
                      await widget.storage
                          .setReminderIntervalHours(v.round());
                      await NotificationService.instance
                          .scheduleReminders(v.round());
                      widget.onChanged();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'You\'ll get a system notification at every slot between 9 AM and 8 PM.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Coach voice',
              child: Column(
                children: [
                  for (final p in CoachPersonality.values)
                    RadioListTile<CoachPersonality>(
                      value: p,
                      groupValue: _coach,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _coach = v);
                        await widget.storage
                            .setCoachPersonalityIndex(v.index);
                        widget.onChanged();
                      },
                      title: Row(
                        children: [
                          Text(p.emoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(p.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      subtitle: Text(p.description),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Appearance',
              child: Column(
                children: [
                  for (final entry in const [
                    (0, 'Auto', 'Match the system theme'),
                    (1, 'Light', 'Bright surfaces, dark text'),
                    (2, 'Dark', 'Dim surfaces, light text'),
                  ])
                    RadioListTile<int>(
                      value: entry.$1,
                      groupValue: _themeMode,
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _themeMode = v);
                        await widget.storage.setThemeModeIndex(v);
                        widget.onChanged();
                      },
                      title: Text(entry.$2,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(entry.$3),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Data',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clear session history'),
                    subtitle: const Text(
                        'Deletes local progress and resets your streak.'),
                    trailing: const Icon(Icons.delete_outline),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear history?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await widget.storage.clearSessions();
                        widget.onChanged();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('History cleared.')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'MoveMate · PhysTech hackathon',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
