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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Flexible(child: _MarelaBrandMark()),
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
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
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: '設定',
                    icon: const Icon(Icons.settings_rounded),
                    iconSize: 26,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: onSettingsTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 公式アセット: アイコン + ワードマーク（横並び）。
class _MarelaBrandMark extends StatelessWidget {
  const _MarelaBrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Marela',
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/brand/marela_icon.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(width: 12),
            Image.asset(
              'assets/brand/marela_wordmark.png',
              height: 36,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ],
        ),
      ),
    );
  }
}
