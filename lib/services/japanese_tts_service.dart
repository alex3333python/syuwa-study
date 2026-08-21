import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Shared Japanese TTS engine. Always speaks ja-JP, regardless of UI language.
class JapaneseTts {
  JapaneseTts._();

  static final JapaneseTts instance = JapaneseTts._();

  FlutterTts? _tts;
  Future<void>? _ready;

  Future<void> warmup() => _ensureReady();

  Future<void> speak(String text) async {
    final spoken = text.trim();
    if (spoken.isEmpty) return;

    if (_tts == null) {
      await _ensureReady();
    }
    final tts = _tts;
    if (tts == null) return;

    await tts.stop();
    await tts.speak(spoken);
  }

  Future<void> stop() async {
    await _tts?.stop();
  }

  Future<void> _ensureReady() {
    return _ready ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      final tts = FlutterTts();
      _tts = tts;
      tts.setErrorHandler((message) {
        debugPrint('Japanese TTS error: $message');
      });

      await tts.setLanguage('ja-JP');
      await tts.setSpeechRate(0.48);
      await tts.setPitch(1.0);
      await tts.setVolume(1.0);
      await tts.awaitSpeakCompletion(false);

      if (!kIsWeb) {
        try {
          await tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
          );
        } catch (_) {
          // Android and desktop ignore iOS audio session setup.
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Japanese TTS init failed: $error\n$stackTrace');
      _tts = null;
    }
  }
}
