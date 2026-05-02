import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'storage.dart';

/// Pain journal — log current pain (0..10) per body area, see a 14-day trend
/// for each area you've ever flagged. Drives the adaptive plan + Smart Coach.
class PainJournalScreen extends StatefulWidget {
  final Storage storage;
  const PainJournalScreen({super.key, required this.storage});

  @override
  State<PainJournalScreen> createState() => _PainJournalScreenState();
}

class _PainJournalScreenState extends State<PainJournalScreen> {
  late Map<BodyArea, int> _today;
  BodyArea? _expanded;

  @override
  void initState() {
    super.initState();
    _today = Map<BodyArea, int>.from(widget.storage.painToday);
  }

  Future<void> _setLevel(BodyArea area, int level) async {
    HapticFeedback.selectionClick();
    setState(() => _today[area] = level);
    await widget.storage.logPain(area, level);
  }

  Future<void> _clear(BodyArea area) async {
    HapticFeedback.lightImpact();
    setState(() => _today.remove(area));
    await widget.storage.clearPain(area);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hotAreas = _today.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final allAreas = BodyArea.values;
    final logged = hotAreas.map((e) => e.key).toSet();
    final remaining = allAreas.where((a) => !logged.contains(a)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pain journal'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF6C00), Color(0xFFD84315)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Text('🩹', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Track what hurts',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.1)),
                        const SizedBox(height: 4),
                        Text(
                          'Tap a body area to set today\'s pain (0–10). High readings flow into your weekly plan and the coach\'s suggestions.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: Colors.white70, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (hotAreas.isNotEmpty) ...[
              Row(
                children: [
                  Text('Today\'s entries',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('${hotAreas.length} logged',
                      style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              for (final entry in hotAreas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PainEntryCard(
                    area: entry.key,
                    level: entry.value,
                    expanded: _expanded == entry.key,
                    onExpand: () => setState(() => _expanded =
                        _expanded == entry.key ? null : entry.key),
                    onSetLevel: (v) => _setLevel(entry.key, v),
                    onClear: () => _clear(entry.key),
                    series: widget.storage.painSeries(entry.key),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Text('Add an area',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${remaining.length} available',
                    style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in remaining)
                  _AreaPill(
                    area: a,
                    onTap: () => _setLevel(a, 5),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PainEntryCard extends StatelessWidget {
  final BodyArea area;
  final int level;
  final bool expanded;
  final VoidCallback onExpand;
  final ValueChanged<int> onSetLevel;
  final VoidCallback onClear;
  final List<int?> series;

  const _PainEntryCard({
    required this.area,
    required this.level,
    required this.expanded,
    required this.onExpand,
    required this.onSetLevel,
    required this.onClear,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _painColor(level);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: color.withValues(alpha: 0.5), width: 1.4),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
      child: Column(
        children: [
          InkWell(
            onTap: onExpand,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Text(area.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(area.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(_painWord(level),
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$level / 10',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(expanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                  onPressed: onExpand,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.2),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: level.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: '$level',
                onChanged: (v) => onSetLevel(v.round()),
              ),
            ),
            const SizedBox(height: 4),
            _PainSparkline(values: series, color: color),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('14-day trend',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Clear today'),
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PainSparkline extends StatelessWidget {
  final List<int?> values;
  final Color color;
  const _PainSparkline({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: CustomPaint(
        painter: _SparkPainter(values: values, color: color),
        size: const Size(double.infinity, 48),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<int?> values;
  final Color color;
  _SparkPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final n = values.length;
    final dx = size.width / (n - 1).clamp(1, 1000);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    final missDot = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.18);

    final path = Path();
    final fillPath = Path();
    bool started = false;
    for (int i = 0; i < n; i++) {
      final v = values[i];
      final x = i * dx;
      if (v == null) {
        canvas.drawCircle(Offset(x, size.height / 2), 2, missDot);
        continue;
      }
      final y = size.height - (v / 10) * size.height;
      if (!started) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, dot);
    }
    if (started) {
      fillPath.lineTo(size.width, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fill);
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _AreaPill extends StatelessWidget {
  final BodyArea area;
  final VoidCallback onTap;
  const _AreaPill({required this.area, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(area.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(area.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(width: 4),
              Icon(Icons.add, size: 14, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

Color _painColor(int level) {
  if (level == 0) return const Color(0xFF9E9E9E);
  if (level <= 3) return const Color(0xFFFFB74D);
  if (level <= 6) return const Color(0xFFFB8C00);
  return const Color(0xFFE53935);
}

String _painWord(int level) {
  if (level == 0) return 'No pain';
  if (level <= 2) return 'Mild';
  if (level <= 4) return 'Noticeable';
  if (level <= 6) return 'Distracting';
  if (level <= 8) return 'Strong';
  return 'Severe';
}
