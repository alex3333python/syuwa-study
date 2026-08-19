import '../models/app_language.dart';

Map<AppLanguage, String> nativeText({
  required String portuguese,
  required String tagalog,
  required String vietnamese,
}) {
  return {
    AppLanguage.portuguese: portuguese,
    AppLanguage.tagalog: tagalog,
    AppLanguage.vietnamese: vietnamese,
  };
}
