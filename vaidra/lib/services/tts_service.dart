// tts_service.dart
// Tiny text-to-speech helper + a speak/stop button widget.
// All failures are swallowed: TTS must never crash a screen.
// Nothing is recorded or uploaded — this only plays synthesised speech.
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._internal();
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<bool> speaking = ValueNotifier<bool>(false);
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setSpeechRate(0.9);
      _tts.setCompletionHandler(() => speaking.value = false);
      _tts.setCancelHandler(() => speaking.value = false);
      _tts.setErrorHandler((_) => speaking.value = false);
      _ready = true;
    } catch (_) {
      // TTS unavailable on this device — speak() will no-op.
    }
  }

  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    try {
      await _ensureReady();
      await _tts.stop();
      speaking.value = true;
      await _tts.speak(clean);
    } catch (_) {
      speaking.value = false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    speaking.value = false;
  }
}

/// Small speak/stop button. Shows a speaker icon; while speaking it shows
/// a stop icon. Tapping toggles. Never throws.
class SpeakButton extends StatelessWidget {
  final String text;
  final Color? color;

  const SpeakButton({Key? key, required this.text, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TtsService().speaking,
      builder: (context, isSpeaking, _) {
        return IconButton(
          icon: Icon(isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
          color: color,
          tooltip: isSpeaking ? 'Stop reading aloud' : 'Read aloud',
          onPressed: () {
            if (isSpeaking) {
              TtsService().stop();
            } else {
              TtsService().speak(text);
            }
          },
        );
      },
    );
  }
}
