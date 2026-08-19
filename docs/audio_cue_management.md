# Audio Cue Management

Audio buttons should identify the phrase they are meant to play with an `AudioCue`.

Current behavior:

- `LearningAudio.play(context, cue)` is the main entry point.
- `LearningAudio.speakJapanese(...)` still works for older call sites and creates a legacy cue.
- If no recorded file is connected yet, the app falls back to the current semantic announcement behavior.

Where to add audio files:

- Put future recordings under `assets/audio/`.
- Add the file path either directly to the matching `AudioCue` through `assetPath`, or centrally in `AudioCueLibrary.assetPathsById`.
- Prefer `AudioCueLibrary.assetPathsById` when a recording is reused or when you want to manage many files in one place.

Cue IDs:

- IDs are generated from namespace, kind, label, and Japanese text.
- Use a stable namespace such as `lesson.supported_instruction`, `lesson.feedback`, or `vocabulary`.
- Do not use the visible button label alone to identify audio. Generic labels such as `操作案内` are allowed only when the cue also carries the exact Japanese text.

Recommended call shape:

```dart
LearningAudio.play(
  context,
  AudioCueFactory.instruction(
    namespace: 'lesson.supported_instruction',
    label: '操作案内',
    text: line.japanese,
    assetPath: 'assets/audio/...',
  ),
);
```

Recommended asset mapping:

```dart
static const Map<String, String> assetPathsById = {
  'lesson.instruction.operation_guide.1234abcd':
      'assets/audio/lesson/instruction/example.mp3',
};
```

Notes:

- The user-facing label can stay generic, such as `操作案内`.
- The cue ID is still unique because it is generated from the namespace, kind, label, and exact Japanese text.
- Dictionary audio should use `AudioCueFactory.vocabulary(term: ...)`, so every word can receive its own recording.
