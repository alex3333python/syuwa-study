import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final int xp;
  final int streak;
  final int level;
  final int xpToNextLevel;
  final VoidCallback onReset;
  final VoidCallback onBack;
  final VoidCallback onOpenRecords;

  const SettingsScreen({
    super.key,
    required this.xp,
    required this.streak,
    required this.onReset,
    required this.onBack,
    required this.level,
    required this.onOpenRecords,
    required this.xpToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFF5F3FF),
            Color(0xFFFDF2F8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Expanded(
                        child: Text(
                          '設定',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.workspace_premium_rounded,
                    iconColor: const Color(0xFF4338CA),
                    title: '現在のレベル',
                    value: 'Lv.$level',
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.bolt_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: '現在のXP',
                    value: '$xp XP',
                  ),
                  _InfoTile(
                    icon: Icons.trending_up_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: '次のレベルまで',
                    value: '$xpToNextLevel XP',
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFF97316),
                    title: '連続記録',
                    value: '$streak 日',
                  ),
                  const SizedBox(height: 12),
                  const _InfoTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: Color(0xFF8B5CF6),
                    title: 'アプリ情報',
                    value: '手話アカデミー v0.1',
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: onReset,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        '進捗をリセット',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}