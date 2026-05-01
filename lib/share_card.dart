import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'models.dart';

class ShareCardData {
  final String planTitle;
  final ExerciseCategory category;
  final int seconds;
  final int? moodDelta;
  final int currentStreak;
  final int wellnessScore;
  final DateTime when;

  const ShareCardData({
    required this.planTitle,
    required this.category,
    required this.seconds,
    required this.moodDelta,
    required this.currentStreak,
    required this.wellnessScore,
    required this.when,
  });
}

class ShareCardWidget extends StatelessWidget {
  final ShareCardData data;
  const ShareCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final mins = data.seconds ~/ 60;
    final secs = data.seconds % 60;
    final timeStr = mins > 0
        ? (secs > 0 ? '${mins}m ${secs}s' : '${mins}m')
        : '${secs}s';
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4D2C), Color(0xFF2EB872), Color(0xFF50C878)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            right: -160,
            child: _bubble(420, 0.12),
          ),
          Positioned(
            top: 280,
            left: -120,
            child: _bubble(280, 0.08),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _bubble(360, 0.10),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(80, 96, 80, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.bolt,
                          color: Color(0xFF2EB872), size: 56),
                    ),
                    const SizedBox(width: 24),
                    const Text(
                      'MoveMate',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 56,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Text(
                  'Just moved.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                    fontSize: 64,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.planTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 96,
                    height: 1.05,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    _Chip(
                      icon: data.category.icon,
                      label: data.category.label,
                    ),
                    const SizedBox(width: 16),
                    _Chip(
                      icon: Icons.schedule,
                      label: timeStr,
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatBlock(
                              value: '${data.currentStreak}',
                              label: data.currentStreak == 1
                                  ? 'day streak'
                                  : 'day streak',
                              emoji: '🔥',
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 90,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          Expanded(
                            child: _StatBlock(
                              value: '${data.wellnessScore}',
                              label: 'wellness score',
                              emoji: '🎯',
                            ),
                          ),
                        ],
                      ),
                      if (data.moodDelta != null && data.moodDelta != 0) ...[
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${data.moodDelta! > 0 ? '+' : ''}${data.moodDelta} mood',
                                style: const TextStyle(
                                  color: Color(0xFF1B4D2C),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 36,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                data.moodDelta! > 0 ? '😊' : '😐',
                                style: const TextStyle(fontSize: 38),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'micro-activity coach',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.30), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;
  const _StatBlock(
      {required this.value, required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 84,
            height: 1,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
            fontSize: 26,
          ),
        ),
      ],
    );
  }
}

Future<Uint8List> renderShareCard(
  BuildContext context,
  ShareCardData data,
) async {
  final completer = Completer<Uint8List>();
  final repaintKey = GlobalKey();
  final overlay = Overlay.of(context, rootOverlay: true);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -10000,
      top: -10000,
      child: Material(
        color: Colors.transparent,
        child: RepaintBoundary(
          key: repaintKey,
          child: ShareCardWidget(data: data),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final ctx = repaintKey.currentContext;
      if (ctx == null) {
        completer.completeError('Repaint context missing');
        entry.remove();
        return;
      }
      final boundary =
          ctx.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        completer.completeError('Encode failed');
      } else {
        completer.complete(byteData.buffer.asUint8List());
      }
    } catch (e) {
      completer.completeError(e);
    } finally {
      entry.remove();
    }
  });

  return completer.future;
}

Future<void> shareSessionCard(
  BuildContext context,
  ShareCardData data, {
  String? text,
}) async {
  final bytes = await renderShareCard(context, data);
  final dir = await getTemporaryDirectory();
  final filename =
      'movemate_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png', name: filename)],
    text: text ?? 'Just moved with MoveMate 💪',
  );
}
