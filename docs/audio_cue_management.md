# Audio Cue Management

Audio buttons should identify the phrase they are meant to play with an `AudioCue`.

Current behavior:

- `LearningAudio.play(context, cue)` is the main entry point.
- `LearningAudio.speakJapanese(...)` still works for older call sites and creates a legacy cue.
- Speech is Japanese TTS (`flutter_tts`, language `ja-JP`), even when the UI language is Portuguese, Tagalog, or Vietnamese.
- Recorded files under `assets/audio/` are kept for now, but playback uses TTS. Do not delete those files until TTS is confirmed on each platform.
- If TTS fails, a short snackbar is shown. Screen readers still receive the original Japanese text.

Spoken text:

- By default, `japaneseText` is rewritten for TTS (for example `÷` → わる, `8:10` → 8時10分, `8cm` → 8センチメートル).
- Dictionary buttons should pass `reading` so kanji is not misread: `AudioCueFactory.vocabulary(term: entry.term, reading: entry.reading)`.
- Call sites can also set `spokenText` when a formula or symbol string needs a dedicated reading.

Where to add audio files (kept until TTS is confirmed):

- Put recordings under `assets/audio/`.
- Add the file path either directly to the matching `AudioCue` through `assetPath`, or centrally in `AudioCueLibrary.assetPathsById`.

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
  ),
);
```
