import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class LearningAudio {
  const LearningAudio._();

  static Future<void> speakJapanese(
    BuildContext context, {
    required String label,
    required String text,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final view = View.of(context);
    final direction = Directionality.of(context);
    await SemanticsService.sendAnnouncement(view, text, direction);
    messenger.showSnackBar(
      SnackBar(
        content: Text('音声「$label」を再生します。'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
