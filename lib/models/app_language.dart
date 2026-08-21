enum AppLanguage { japanese, portuguese, tagalog, vietnamese }

extension AppLanguageLabel on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.japanese:
        return '日本語';
      case AppLanguage.portuguese:
        return 'Português';
      case AppLanguage.tagalog:
        return 'Tagalog';
      case AppLanguage.vietnamese:
        return 'Tiếng Việt';
    }
  }

  String get storageValue => name;

  static AppLanguage fromStorageValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'portuguese':
      case 'português':
      case 'pt':
        return AppLanguage.portuguese;
      case 'tagalog':
      case 'filipino':
      case 'tl':
        return AppLanguage.tagalog;
      case 'vietnamese':
      case 'tiếng việt':
      case 'tieng viet':
      case 'vi':
        return AppLanguage.vietnamese;
      case 'japanese':
      case '日本語':
      case 'ja':
        return AppLanguage.japanese;
    }
    return AppLanguage.values.firstWhere(
      (language) => language.storageValue == value,
      orElse: () => AppLanguage.japanese,
    );
  }
}

/// Prompt toggle for the learner's language. Japanese is やさしい日本語, not a second 日本語.
String nativePromptModeLabel(AppLanguage language) {
  return language == AppLanguage.japanese ? 'やさしい日本語' : language.label;
}

/// On-screen lesson step titles. Harder kanji are written in hiragana.
String lessonStepTitleForDisplay(String title, AppLanguage language) {
  switch (title) {
    case 'いっしょに解こう':
    case 'いっしょにとこう':
      return 'いっしょにとこう';
    case '自分で解こう':
    case '自分でとこう':
      return '自分でとこう';
    case '日本語だけで挑戦':
    case '日本語にちょうせん':
    case 'さらにちょうせん':
      return language == AppLanguage.japanese
          ? 'さらにちょうせん'
          : '日本語にちょうせん';
    default:
      return title;
  }
}

bool isJapaneseOnlyChallengeTitle(String? title) {
  return title == '日本語だけで挑戦' ||
      title == '日本語にちょうせん' ||
      title == 'さらにちょうせん';
}

bool looksLikeJapaneseGloss(String value) {
  return value.contains('です。') ||
      value.contains('ことです。') ||
      value.contains('ことです');
}

/// Looks up a native-language string. Never returns Japanese fallback text.
String lookupNative(
  Map<AppLanguage, String> translations,
  AppLanguage language,
) {
  if (language == AppLanguage.japanese) return '';

  String? usable(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || looksLikeJapaneseGloss(trimmed)) return null;
    return trimmed;
  }

  final direct = usable(translations[language]);
  if (direct != null) return direct;

  for (final entry in translations.entries) {
    if (entry.key.name == language.name) {
      final matched = usable(entry.value);
      if (matched != null) return matched;
    }
  }
  return '';
}
