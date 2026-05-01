import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const List<String> moodEmoji = ['😣', '😐', '🙂', '😊', '🤩'];
const List<String> moodLabels = ['Rough', 'Meh', 'OK', 'Good', 'Great'];

class MoodPicker extends StatefulWidget {
  final int? initial;
  final ValueChanged<int> onChanged;
  const MoodPicker({super.key, this.initial, required this.onChanged});

  @override
  State<MoodPicker> createState() => _MoodPickerState();
}

class _MoodPickerState extends State<MoodPicker> {
  int? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (i) {
        final m = i + 1;
        final selected = _value == m;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _value = m);
              widget.onChanged(m);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 1.6,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.18 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    child: Text(moodEmoji[i],
                        style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(height: 4),
                  Text(moodLabels[i],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w500,
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          )),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Modal sheet that asks for a mood reading. Returns null if user dismisses.
Future<int?> askForMood(
  BuildContext context, {
  required String title,
  required String subtitle,
  String confirmLabel = 'Continue',
  String? skipLabel = 'Skip',
}) async {
  int? selected;
  final result = await showModalBottomSheet<int?>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 18),
              MoodPicker(
                initial: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (skipLabel != null)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: Text(skipLabel),
                      ),
                    ),
                  if (skipLabel != null) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: selected == null
                          ? null
                          : () => Navigator.of(ctx).pop(selected),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      });
    },
  );
  return result;
}
