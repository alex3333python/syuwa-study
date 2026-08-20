import 'package:flutter/material.dart';

import '../models/app_language.dart';

/// Provides the lesson's selected language to dictionary and native lines.
class LessonLanguageScope extends InheritedWidget {
  final AppLanguage language;

  const LessonLanguageScope({
    required this.language,
    required super.child,
  });

  static LessonLanguageScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LessonLanguageScope>();
  }

  static AppLanguage of(BuildContext context, AppLanguage fallback) {
    return maybeOf(context)?.language ?? fallback;
  }

  @override
  bool updateShouldNotify(LessonLanguageScope oldWidget) {
    return language != oldWidget.language;
  }
}
