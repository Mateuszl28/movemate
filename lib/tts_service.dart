import 'package:flutter_tts/flutter_tts.dart';

enum CoachPersonality { calm, upbeat, strict }

extension CoachPersonalityX on CoachPersonality {
  String get label {
    switch (this) {
      case CoachPersonality.calm:
        return 'Calm';
      case CoachPersonality.upbeat:
        return 'Upbeat';
      case CoachPersonality.strict:
        return 'Strict';
    }
  }

  String get description {
    switch (this) {
      case CoachPersonality.calm:
        return 'Soft pace, mellow voice — for stretching and recovery.';
      case CoachPersonality.upbeat:
        return 'Faster, brighter — for energy boosts and cardio.';
      case CoachPersonality.strict:
        return 'Steady and direct — for focus blocks and discipline.';
    }
  }

  String get emoji {
    switch (this) {
      case CoachPersonality.calm:
        return '🧘';
      case CoachPersonality.upbeat:
        return '⚡';
      case CoachPersonality.strict:
        return '🎯';
    }
  }

  double get rate {
    switch (this) {
      case CoachPersonality.calm:
        return 0.42;
      case CoachPersonality.upbeat:
        return 0.55;
      case CoachPersonality.strict:
        return 0.50;
    }
  }

  double get pitch {
    switch (this) {
      case CoachPersonality.calm:
        return 0.95;
      case CoachPersonality.upbeat:
        return 1.10;
      case CoachPersonality.strict:
        return 0.90;
    }
  }
}

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool enabled = true;
  CoachPersonality personality = CoachPersonality.calm;

  Future<void> init({CoachPersonality? personality}) async {
    if (personality != null) this.personality = personality;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(this.personality.rate);
    await _tts.setPitch(this.personality.pitch);
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
