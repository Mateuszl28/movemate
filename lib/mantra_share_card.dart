import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'daily_mantra.dart';

/// 1080x1920 portrait quote card for the day's mantra. Designed to be
/// screenshot-shared as a daily affirmation.
class MantraShareCard extends StatelessWidget {
  final Mantra mantra;
  final DateTime when;
  const MantraShareCard({super.key, required this.mantra, required this.when});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEEE · MMM d, yyyy');
    return Container(
      width: 1080,
      height: 1920,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B4D2C),
            Color(0xFF2EB872),
            Color(0xFF50C878),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -200, right: -180, child: _bubble(540, 0.10)),
          Positioned(bottom: -140, left: -160, child: _bubble(420, 0.08)),
          Positioned(top: 360, left: -100, child: _bubble(220, 0.05)),
          Padding(
            padding: const EdgeInsets.fromLTRB(80, 100, 80, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('⚡',
                          style: TextStyle(fontSize: 44)),
                    ),
                    const SizedBox(width: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MoveMate',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 36,
                              letterSpacing: -1,
                            )),
                        Text('today\'s mantra',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              letterSpacing: 1.4,
                            )),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(mantra.emoji,
                    style: const TextStyle(fontSize: 144)),
                const SizedBox(height: 28),
                Text(
                  '"${mantra.text}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 76,
                    height: 1.18,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  df.format(when),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
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

Future<Uint8List> renderMantraShare(
    BuildContext context, Mantra mantra, DateTime when) async {
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
          child: MantraShareCard(mantra: mantra, when: when),
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

Future<void> shareDailyMantra(
    BuildContext context, Mantra mantra, DateTime when) async {
  final bytes = await renderMantraShare(context, mantra, when);
  final dir = await getTemporaryDirectory();
  final filename =
      'movemate_mantra_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png', name: filename)],
    text: '${mantra.emoji} "${mantra.text}" — MoveMate',
  );
}
