import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Shared Japanese TTS engine. Always speaks ja-JP, regardless of UI language.
///
/// On Flutter Web (especially Safari / iPad), speechSynthesis often requires a
/// user gesture before the first utterance. Call [speak] from a tap/button
/// handler; this service also re-applies ja-JP before each speak on web.
class JapaneseTts {
  JapaneseTts._();

  static final JapaneseTts instance = JapaneseTts._();

  FlutterTts? _tts;
  Future<void>? _ready;
  bool _webUnlocked = false;

  Future<void> warmup() => _ensureReady();

  Future<void> speak(String text) async {
    final spoken = text.trim();
    if (spoken.isEmpty) return;

    if (_tts == null) {
      await _ensureReady();
    }
    final tts = _tts;
    if (tts == null) return;

    try {
      // Safari / iOS WebKit: language can be ignored after init; re-assert.
      if (kIsWeb) {
        await tts.setLanguage('ja-JP');
        if (!_webUnlocked) {
          // Prime the engine inside the current user-gesture stack.
          try {
            await tts.speak(' ');
            await tts.stop();
          } catch (_) {
            // Ignored — first real speak may still succeed after gesture.
          }
          _webUnlocked = true;
        }
      }

      await tts.stop();
      await tts.speak(spoken);
    } catch (error, stackTrace) {
      debugPrint('Japanese TTS speak failed: $error\n$stackTrace');
      rethrow;
    }
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
      _ready = null;
    }
  }
}
