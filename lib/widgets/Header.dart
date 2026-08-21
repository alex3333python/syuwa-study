import 'package:flutter/material.dart';

import '../models/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _MarelaBrandMark(),
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

/// 白い角丸アイコン + 紺の「Marela」タイトル（横並び）。
class _MarelaBrandMark extends StatelessWidget {
  const _MarelaBrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Marela',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/brand/marela_icon.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(width: 10),
          const Text(
            'Marela',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavy,
              letterSpacing: 0.2,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
