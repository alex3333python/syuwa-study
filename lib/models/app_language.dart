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
    return AppLanguage.values.firstWhere(
      (language) => language.storageValue == value,
      orElse: () => AppLanguage.japanese,
    );
  }
}
