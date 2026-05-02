import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'storage.dart';

/// Quick sleep journal: pick last night's hours and a 1-5 quality rating.
/// One entry per day; logging again replaces the prior entry.
class SleepScreen extends StatefulWidget {
  final Storage storage;
  const SleepScreen({super.key, required this.storage});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  double _hours = 7.5;
  int _quality = 3;

  @override
  void initState() {
    super.initState();
    final last = widget.storage.latestSleep;
    if (last != null) {
      _hours = last.hours;
      _quality = last.quality;
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    await widget.storage.logSleep(_hours, _quality);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _qualityLabel(int q) {
    switch (q) {
      case 1:
        return 'Restless';
      case 2:
        return 'Patchy';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
      default:
        return 'Deep';
    }
  }

  String _qualityEmoji(int q) {
    switch (q) {
      case 1:
        return '😵';
      case 2:
        return '😪';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
      default:
        return '😴';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avg = widget.storage.sleepAverageHours();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep journal'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF311B92)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 48)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('How did you sleep?',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1)),
                          const SizedBox(height: 4),
                          Text(
                            avg == null
                                ? 'No history yet — log your first night.'
                                : '7-day average: ${avg.toStringAsFixed(1)} h',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
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
                        Text('Hours slept',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text(_hours.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                fontFeatures: [
                                  FontFeature.tabularFigures()
                                ])),
                      ],
                    ),
                    Slider(
                      value: _hours,
                      min: 3,
                      max: 12,
                      divisions: 36,
                      label: '${_hours.toStringAsFixed(1)} h',
                      onChanged: (v) => setState(() => _hours = v),
                    ),
                    Text(
                      _hoursHint(_hours),
                      style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quality',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 1; i <= 5; i++)
                          _QualityDot(
                            emoji: _qualityEmoji(i),
                            label: _qualityLabel(i),
                            selected: _quality == i,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _quality = i);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save sleep entry',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hoursHint(double h) {
    if (h < 6) return 'Short night — extra gentle plans today.';
    if (h < 7) return 'A bit short — easy on the cardio.';
    if (h <= 9) return 'Solid window — full slate of options.';
    return 'Long sleep — ease in slowly.';
  }
}

class _QualityDot extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _QualityDot({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color:
                          selected ? scheme.primary : scheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
