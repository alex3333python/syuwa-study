import '../models/audio_cue.dart';

abstract final class AudioCueNamespaces {
  static const String legacy = 'legacy';
  static const String lesson = 'lesson';
  static const String vocabulary = 'vocabulary';
  static const String instruction = 'instruction';
  static const String explanation = 'explanation';
  static const String feedback = 'feedback';
}

abstract final class AudioCueFactory {
  static AudioCue problem({
    required String namespace,
    required String label,
    required String text,
    String? spokenText,
    String? assetPath,
  }) {
    return AudioCue.inline(
      namespace: namespace,
      kind: AudioCueKind.problem,
      label: label,
      text: text,
      spokenText: spokenText,
      assetPath: assetPath,
    );
  }

  static AudioCue instruction({
    required String namespace,
    required String label,
    required String text,
    String? spokenText,
    String? assetPath,
  }) {
    return AudioCue.inline(
      namespace: namespace,
      kind: AudioCueKind.instruction,
      label: label,
      text: text,
      spokenText: spokenText,
      assetPath: assetPath,
    );
  }

  static AudioCue explanation({
    required String namespace,
    required String label,
    required String text,
    String? spokenText,
    String? assetPath,
  }) {
    return AudioCue.inline(
      namespace: namespace,
      kind: AudioCueKind.explanation,
      label: label,
      text: text,
      spokenText: spokenText,
      assetPath: assetPath,
    );
  }

  static AudioCue vocabulary({
    required String term,
    String? reading,
    String? assetPath,
  }) {
    return AudioCue.inline(
      namespace: AudioCueNamespaces.vocabulary,
      kind: AudioCueKind.vocabulary,
      label: term,
      text: term,
      spokenText: reading,
      assetPath: assetPath,
    );
  }

  static AudioCue legacy({
    required String label,
    required String text,
    String? spokenText,
    AudioCueKind kind = AudioCueKind.other,
    String? id,
    String? assetPath,
  }) {
    if (id != null) {
      return AudioCue(
        id: id,
        label: label,
        japaneseText: text,
        spokenText: spokenText,
        kind: kind,
        assetPath: assetPath,
      );
    }
    return AudioCue.inline(
      namespace: AudioCueNamespaces.legacy,
      kind: kind,
      label: label,
      text: text,
      spokenText: spokenText,
      assetPath: assetPath,
    );
  }
}

abstract final class AudioCueLibrary {
  // Add recorded files here as they become available.
  //
  // Audio files are keyed by AudioCue.id. The id includes the namespace, kind,
  // visible label, and spoken Japanese text, so labels such as "操作案内" still
  // become separate cues when the actual phrase is different.
  //
  // Put files under assets/audio/... and register each cue id here.
  //
  // Example:
  // static const Map<String, String> assetPathsById = {
  //   'lesson.instruction.operation_guide.1234abcd':
  //       'assets/audio/lesson/instruction/example.mp3',
  // };
  static const Map<String, String> assetPathsById = <String, String>{};

  static AudioCue resolve(AudioCue cue) {
    return cue.withAssetPath(cue.assetPath ?? assetPathsById[cue.id]);
  }
}
