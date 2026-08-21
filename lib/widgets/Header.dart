import 'package:flutter/material.dart';

import '../models/app_language.dart';

class Header extends StatelessWidget {
  final AppLanguage language;
  final VoidCallback onSettingsTap;

  const Header({
    super.key,
    required this.language,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  ),
                ),
                child: const Center(
                  child: Text(
                    '算',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '多言語算数学習',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  // Teal — distinct from the old streak (orange), XP (yellow),
                  // and level (indigo) pills.
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  language.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: '設定',
                icon: const Icon(Icons.settings_rounded),
                onPressed: onSettingsTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
