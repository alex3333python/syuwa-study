import 'package:flutter/material.dart';

import '../data/glossary.dart';
import '../models/app_language.dart';

class WordPopup extends StatelessWidget {
  final GlossaryEntry entry;
  final AppLanguage language;
  final Widget child;

  const WordPopup({
    super.key,
    required this.entry,
    required this.language,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(entry.word),
              content: Text(entry.meaningFor(language)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ],
            );
          },
        );
      },
      child: child,
    );
  }
}
