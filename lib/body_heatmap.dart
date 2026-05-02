import 'package:flutter/material.dart';

import 'models.dart';

/// Stylised front-view body diagram. Each region tints by current pain level
/// (gray → amber → orange → red). Tapping a region calls [onTap] with the
/// matching [BodyArea] so the parent can prompt for a level.
///
/// Renders inside a fixed 220×380 logical Stack. Wrap in `Center` /
/// `Padding` for placement.
class BodyHeatmap extends StatelessWidget {
  final Map<BodyArea, int> pain; // 0..10 per area
  final ValueChanged<BodyArea> onTap;

  const BodyHeatmap({super.key, required this.pain, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 220,
        height: 380,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Head — clickable head/neck combined region.
            _Region(
              left: 80,
              top: 0,
              width: 60,
              height: 60,
              shape: BoxShape.circle,
              area: BodyArea.neck,
              pain: pain[BodyArea.neck] ?? 0,
              onTap: onTap,
              showLabel: false,
              label: '🙂',
            ),
            // Neck capsule (also Neck area, smaller).
            _Region(
              left: 96,
              top: 58,
              width: 28,
              height: 14,
              area: BodyArea.neck,
              pain: pain[BodyArea.neck] ?? 0,
              onTap: onTap,
              showLabel: false,
              radius: 5,
            ),
            // Shoulders bar.
            _Region(
              left: 30,
              top: 70,
              width: 160,
              height: 22,
              area: BodyArea.shoulders,
              pain: pain[BodyArea.shoulders] ?? 0,
              onTap: onTap,
              radius: 11,
            ),
            // Left arm / wrist column.
            _Region(
              left: 20,
              top: 96,
              width: 18,
              height: 120,
              area: BodyArea.wrists,
              pain: pain[BodyArea.wrists] ?? 0,
              onTap: onTap,
              showLabel: false,
              radius: 9,
            ),
            // Right arm / wrist column.
            _Region(
              left: 182,
              top: 96,
              width: 18,
              height: 120,
              area: BodyArea.wrists,
              pain: pain[BodyArea.wrists] ?? 0,
              onTap: onTap,
              showLabel: false,
              radius: 9,
            ),
            // Chest.
            _Region(
              left: 55,
              top: 96,
              width: 110,
              height: 56,
              area: BodyArea.chest,
              pain: pain[BodyArea.chest] ?? 0,
              onTap: onTap,
              radius: 16,
            ),
            // Core (abdomen).
            _Region(
              left: 60,
              top: 156,
              width: 100,
              height: 52,
              area: BodyArea.core,
              pain: pain[BodyArea.core] ?? 0,
              onTap: onTap,
              radius: 14,
            ),
            // Hips bar.
            _Region(
              left: 50,
              top: 212,
              width: 120,
              height: 28,
              area: BodyArea.hips,
              pain: pain[BodyArea.hips] ?? 0,
              onTap: onTap,
              radius: 14,
            ),
            // Left leg.
            _Region(
              left: 64,
              top: 246,
              width: 38,
              height: 110,
              area: BodyArea.legs,
              pain: pain[BodyArea.legs] ?? 0,
              onTap: onTap,
              showLabel: false,
              radius: 16,
            ),
            // Right leg.
            _Region(
              left: 118,
              top: 246,
              width: 38,
              height: 110,
              area: BodyArea.legs,
              pain: pain[BodyArea.legs] ?? 0,
              onTap: onTap,
              showLabel: false,
              radius: 16,
            ),
            // Feet / ankles.
            _Region(
              left: 50,
              top: 360,
              width: 120,
              height: 18,
              area: BodyArea.ankles,
              pain: pain[BodyArea.ankles] ?? 0,
              onTap: onTap,
              radius: 8,
            ),
            // Back side button — front view doesn't show it, so we place a
            // floating chip to the right of the chest.
            Positioned(
              left: 168,
              top: 138,
              child: _BackChip(
                pain: pain[BodyArea.back] ?? 0,
                onTap: () => onTap(BodyArea.back),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Region extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final double height;
  final BodyArea area;
  final int pain;
  final ValueChanged<BodyArea> onTap;
  final BoxShape shape;
  final double radius;
  final bool showLabel;
  final String? label;

  const _Region({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.area,
    required this.pain,
    required this.onTap,
    this.shape = BoxShape.rectangle,
    this.radius = 12,
    this.showLabel = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = _heatColor(pain);
    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: shape == BoxShape.circle
              ? const CircleBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius)),
          onTap: () => onTap(area),
          child: Tooltip(
            message: '${area.label}${pain > 0 ? " · $pain/10" : ""}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color.fill,
                shape: shape,
                borderRadius: shape == BoxShape.rectangle
                    ? BorderRadius.circular(radius)
                    : null,
                border: Border.all(color: color.border, width: 1.6),
                boxShadow: pain > 0
                    ? [
                        BoxShadow(
                          color: color.border.withValues(alpha: 0.45),
                          blurRadius: 12,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : const [],
              ),
              alignment: Alignment.center,
              child: label != null
                  ? Text(label!, style: const TextStyle(fontSize: 26))
                  : showLabel && pain > 0
                      ? Text('$pain',
                          style: TextStyle(
                              color: color.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 13))
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackChip extends StatelessWidget {
  final int pain;
  final VoidCallback onTap;
  const _BackChip({required this.pain, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _heatColor(pain);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.fill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.border, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new,
                  size: 10, color: color.text),
              const SizedBox(width: 4),
              Text('Back',
                  style: TextStyle(
                      color: color.text,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
              if (pain > 0) ...[
                const SizedBox(width: 4),
                Text('$pain',
                    style: TextStyle(
                        color: color.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w900)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeatColor {
  final Color fill;
  final Color border;
  final Color text;
  const _HeatColor(this.fill, this.border, this.text);
}

_HeatColor _heatColor(int pain) {
  if (pain == 0) {
    return const _HeatColor(
      Color(0xFFE0E0E0),
      Color(0x33000000),
      Color(0xFF424242),
    );
  }
  if (pain <= 3) {
    return const _HeatColor(
      Color(0xFFFFE0B2),
      Color(0xFFFFB74D),
      Color(0xFF7C4D00),
    );
  }
  if (pain <= 6) {
    return const _HeatColor(
      Color(0xFFFFCC80),
      Color(0xFFFB8C00),
      Color(0xFF8B3F00),
    );
  }
  return const _HeatColor(
    Color(0xFFFFAB91),
    Color(0xFFE53935),
    Color(0xFF8B1010),
  );
}
