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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'やさしい日本語',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(entry.easyJa),
                  if (language != AppLanguage.japanese) ...[
                    const SizedBox(height: 16),
                    Text(
                      language.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(entry.nativeMeaningFor(language)),
                  ],
                ],
              ),
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
