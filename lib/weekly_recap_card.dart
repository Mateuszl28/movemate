import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'insights.dart';
import 'models.dart';
import 'storage.dart';

/// 1080x1920 portrait card summarising the past 7 days. Designed to be
/// screenshot-shared so the user can post their weekly streak.
class WeeklyRecapCard extends StatelessWidget {
  final WeeklyRecapData data;
  const WeeklyRecapCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d');
    final start = data.insights.last7Days.first.date;
    final end = data.insights.last7Days.last.date;
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2EB872),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -200, right: -200, child: _bubble(560, 0.10)),
          Positioned(bottom: -160, left: -160, child: _bubble(440, 0.07)),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 80, 72, 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF50C878), Color(0xFF2EB872)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: const Text('📈',
                          style: TextStyle(fontSize: 50)),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekly recap',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 56,
                                height: 1,
                                letterSpacing: -1,
                              )),
                          const SizedBox(height: 6),
                          Text(
                            '${df.format(start)} – ${df.format(end)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w600,
                              fontSize: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                Container(
                  padding: const EdgeInsets.fromLTRB(36, 32, 36, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total this week',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${data.insights.totalMinutes}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 168,
                              height: 1,
                              letterSpacing: -3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Text(
                              'min',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${data.insights.activeDays} of 7 active days · streak ${data.streak} 🔥',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.fromLTRB(36, 30, 36, 26),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Day by day',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 32,
                          )),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 320,
                        child: _DayBars(insights: data.insights),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        emoji: '⭐',
                        title: data.insights.topCategory?.label ?? '—',
                        subtitle: data.insights.topCategory == null
                            ? 'No focus yet'
                            : 'Top focus',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _StatTile(
                        emoji: data.moodEmoji,
                        title: data.moodTitle,
                        subtitle: data.moodSubtitle,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF29B6F6)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text('⚡',
                          style: TextStyle(fontSize: 30)),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        'MoveMate · micro-activity coach',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
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

class _DayBars extends StatelessWidget {
  final WeeklyInsights insights;
  const _DayBars({required this.insights});

  @override
  Widget build(BuildContext context) {
    final maxMin = insights.last7Days
        .fold<int>(1, (m, d) => d.minutes > m ? d.minutes : m);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final d in insights.last7Days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (d.minutes > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('${d.minutes}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          )),
                    ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      height: (d.minutes / maxMin) * 220,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF50C878),
                            Color(0xFFB9F6CA),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(d.label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      )),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _StatTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.18), width: 2),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      height: 1,
                    )),
                const SizedBox(height: 6),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyRecapData {
  final WeeklyInsights insights;
  final int streak;
  final String moodEmoji;
  final String moodTitle;
  final String moodSubtitle;

  const WeeklyRecapData({
    required this.insights,
    required this.streak,
    required this.moodEmoji,
    required this.moodTitle,
    required this.moodSubtitle,
  });

  factory WeeklyRecapData.fromStorage(Storage storage) {
    final insights = WeeklyInsights.from(storage.sessions);
    final mood = insights.averageMoodDelta;
    String emoji;
    String title;
    String sub;
    if (mood == null) {
      emoji = '🌿';
      title = 'No mood data';
      sub = 'Log moods';
    } else if (mood >= 0.5) {
      emoji = '✨';
      title = '+${mood.toStringAsFixed(1)} mood';
      sub = '${insights.moodTrackedSessions} sessions';
    } else if (mood >= -0.2) {
      emoji = '🌿';
      title = 'Steady mood';
      sub = '${insights.moodTrackedSessions} sessions';
    } else {
      emoji = '💭';
      title = '${mood.toStringAsFixed(1)} mood';
      sub = 'Try a calmer day';
    }
    return WeeklyRecapData(
      insights: insights,
      streak: storage.currentStreak,
      moodEmoji: emoji,
      moodTitle: title,
      moodSubtitle: sub,
    );
  }
}

Future<Uint8List> renderWeeklyRecap(
    BuildContext context, WeeklyRecapData data) async {
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
          child: WeeklyRecapCard(data: data),
        ),
      ),
    ),
  );
  overlay.insert(entry);

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 90));
      final ctx = repaintKey.currentContext;
      if (ctx == null) {
        completer.completeError('Repaint context missing');
        entry.remove();
        return;
      }
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary;
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

Future<void> shareWeeklyRecap(BuildContext context, Storage storage) async {
  final data = WeeklyRecapData.fromStorage(storage);
  final bytes = await renderWeeklyRecap(context, data);
  final dir = await getTemporaryDirectory();
  final filename =
      'movemate_recap_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png', name: filename)],
    text:
        'My week with MoveMate: ${data.insights.totalMinutes} min · ${data.insights.activeDays}/7 active days 💪',
  );
}
