import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool enabled = true;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(false);
    _ready = true;
  }

  Future<void> speak(String text) async {
    if (!enabled) return;
    if (!_ready) await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    if (_ready) await _tts.stop();
  }

  Future<void> dispose() async {
    if (_ready) {
      await _tts.stop();
    }
  }
}
