enum AudioCueKind {
  problem,
  instruction,
  explanation,
  vocabulary,
  result,
  formula,
  interaction,
  other,
}

final class AudioCue {
  final String id;
  final String label;
  final String japaneseText;
  final String? spokenText;
  final String? assetPath;
  final AudioCueKind kind;

  const AudioCue({
    required this.id,
    required this.label,
    required this.japaneseText,
    required this.kind,
    this.spokenText,
    this.assetPath,
  });

  factory AudioCue.inline({
    required String namespace,
    required AudioCueKind kind,
    required String label,
    required String text,
    String? spokenText,
    String? assetPath,
  }) {
    return AudioCue(
      id: AudioCueId.build(
        namespace: namespace,
        kind: kind,
        label: label,
        text: text,
      ),
      label: label,
      japaneseText: text,
      spokenText: spokenText,
      kind: kind,
      assetPath: assetPath,
    );
  }

  AudioCue withAssetPath(String? path) {
    if (path == null || path == assetPath) return this;
    return AudioCue(
      id: id,
      label: label,
      japaneseText: japaneseText,
      spokenText: spokenText,
      kind: kind,
      assetPath: path,
    );
  }
}

abstract final class AudioCueId {
  static String build({
    required String namespace,
    required AudioCueKind kind,
    required String label,
    required String text,
  }) {
    final scope = _slug(namespace);
    final name = _slug(label);
    final hash = _stableHash('$namespace|${kind.name}|$label|$text');
    return '$scope.${kind.name}.$name.$hash';
  }

  static String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'cue' : slug;
  }

  static String _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
