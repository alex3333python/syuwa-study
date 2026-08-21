import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../data/audio_cues.dart';
import '../models/audio_cue.dart';
import 'japanese_speech_text.dart';
import 'japanese_tts_service.dart';

class LearningAudio {
  const LearningAudio._();

  static Future<void> speakJapanese(
    BuildContext context, {
    required String label,
    required String text,
    String? spokenText,
    String? id,
    String? assetPath,
    AudioCueKind kind = AudioCueKind.other,
  }) async {
    await play(
      context,
      AudioCueFactory.legacy(
        id: id,
        label: label,
        text: text,
        spokenText: spokenText,
        kind: kind,
        assetPath: assetPath,
      ),
    );
  }

  static Future<void> play(BuildContext context, AudioCue cue) async {
    final resolvedCue = AudioCueLibrary.resolve(cue);
    final text = resolvedCue.japaneseText.trim();
    if (text.isEmpty && (resolvedCue.spokenText?.trim().isEmpty ?? true)) {
      return;
    }

    final spoken = JapaneseSpeechText.fromCue(
      japaneseText: resolvedCue.japaneseText,
      spokenText: resolvedCue.spokenText,
    );
    if (spoken.isEmpty) return;

    unawaited(() async {
      try {
        await JapaneseTts.instance.speak(spoken);
      } catch (error, stackTrace) {
        debugPrint('Japanese TTS failed: $error\n$stackTrace');
        if (!context.mounted) return;
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
          SnackBar(
            content: Text('音声「${resolvedCue.label}」を再生できませんでした。'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }());

    final view = View.of(context);
    final direction = Directionality.of(context);
    await SemanticsService.sendAnnouncement(
      view,
      text.isEmpty ? spoken : text,
      direction,
    );
  }
}
