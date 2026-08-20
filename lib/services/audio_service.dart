import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../data/audio_cues.dart';
import '../models/audio_cue.dart';

class LearningAudio {
  const LearningAudio._();

  static Future<void> speakJapanese(
    BuildContext context, {
    required String label,
    required String text,
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
        kind: kind,
        assetPath: assetPath,
      ),
    );
  }

  static Future<void> play(BuildContext context, AudioCue cue) async {
    final resolvedCue = AudioCueLibrary.resolve(cue);
    final text = resolvedCue.japaneseText.trim();
    if (text.isEmpty) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final view = View.of(context);
    final direction = Directionality.of(context);
    await SemanticsService.sendAnnouncement(view, text, direction);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('音声「${resolvedCue.label}」を再生します。'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
