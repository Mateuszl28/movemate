import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'demo_seeder.dart';
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
  late int _quietStart;
  late int _quietEnd;

  @override
  void initState() {
    super.initState();
    _profile = widget.storage.profile;
    _reminderHours = widget.storage.reminderIntervalHours;
    _dailyGoal = widget.storage.dailyGoalMinutes;
    _themeMode = widget.storage.themeModeIndex;
    _coach = CoachPersonality.values[widget.storage.coachPersonalityIndex];
    _hydrationGoal = widget.storage.hydrationGoalGlasses;
    _quietStart = widget.storage.quietHoursStart;
    _quietEnd = widget.storage.quietHoursEnd;
  }

  Future<void> _persistQuietHours() async {
    await widget.storage.setQuietHours(_quietStart, _quietEnd);
    await NotificationService.instance.scheduleReminders(
      _reminderHours,
      quietStart: _quietStart,
      quietEnd: _quietEnd,
    );
    widget.onChanged();
  }

  String _hourLabel(int h) {
    final hh = h.toString().padLeft(2, '0');
    return '$hh:00';
  }

  Future<void> _loadDemoData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load demo data?'),
        content: const Text(
            'Replaces all current data with a 30-day realistic snapshot — sessions, pain trend, sleep, energy, hydration, eye breaks, posture. Useful for showcasing the app in a demo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Load demo'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await widget.storage.replaceWithImport(DemoSeeder.generate());
    widget.onChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo data loaded.')),
    );
  }

  Future<void> _exportData() async {
    final json = widget.storage.exportAll();
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final filename = 'movemate_backup_$stamp.json';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json', name: filename)],
      text: 'MoveMate backup · $stamp',
    );
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
              icon: Icons.accessibility_new,
              accent: const Color(0xFF2EB872),
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
              icon: Icons.flag_outlined,
              accent: const Color(0xFFE57373),
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
              icon: Icons.water_drop_outlined,
              accent: const Color(0xFF1E88E5),
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
              icon: Icons.notifications_active_outlined,
              accent: const Color(0xFFFFB74D),
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
                      await NotificationService.instance.scheduleReminders(
                        v.round(),
                        quietStart: _quietStart,
                        quietEnd: _quietEnd,
                      );
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
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_active, size: 18),
                      label: const Text('Send test notification'),
                      onPressed: () async {
                        await NotificationService.instance.showTestNow();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Sent — pull down notifications to preview.'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Quiet hours',
              icon: Icons.bedtime_outlined,
              accent: const Color(0xFF7B5CFF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _quietStart == _quietEnd
                          ? 'Disabled — reminders fire at every slot'
                          : 'No reminders ${_hourLabel(_quietStart)} → ${_hourLabel(_quietEnd)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Start',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w800)),
                  Slider(
                    value: _quietStart.toDouble(),
                    min: 0,
                    max: 23,
                    divisions: 23,
                    label: _hourLabel(_quietStart),
                    onChanged: (v) =>
                        setState(() => _quietStart = v.round()),
                    onChangeEnd: (v) => _persistQuietHours(),
                  ),
                  Text('End',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w800)),
                  Slider(
                    value: _quietEnd.toDouble(),
                    min: 0,
                    max: 23,
                    divisions: 23,
                    label: _hourLabel(_quietEnd),
                    onChanged: (v) =>
                        setState(() => _quietEnd = v.round()),
                    onChangeEnd: (v) => _persistQuietHours(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Set both to the same hour to disable. The window may wrap past midnight (e.g. 22:00 → 08:00).',
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
              icon: Icons.record_voice_over_outlined,
              accent: const Color(0xFF26A69A),
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
              icon: Icons.palette_outlined,
              accent: const Color(0xFF8E24AA),
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
              icon: Icons.dataset_outlined,
              accent: const Color(0xFF607D8B),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Backup data'),
                    subtitle: const Text(
                        'Share a JSON dump of every setting, session, and log.'),
                    trailing: const Icon(Icons.ios_share),
                    onTap: _exportData,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Load demo data'),
                    subtitle: const Text(
                        'Replace local state with a 30-day realistic snapshot.'),
                    trailing: const Icon(Icons.science_outlined),
                    onTap: _loadDemoData,
                  ),
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
  final IconData? icon;
  final Color? accent;
  final Widget child;
  const _Section({
    required this.title,
    this.icon,
    this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accent ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
