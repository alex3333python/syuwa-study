import 'package:flutter/material.dart';

import '../logic/weak_signal_mapper.dart';
import '../theme/app_colors.dart';

class ReportScreen extends StatelessWidget {
  final Map<String, int> weakUnitCounts;
  final Map<String, int> weakSectionCounts;

  const ReportScreen({
    super.key,
    required this.weakUnitCounts,
    required this.weakSectionCounts,
  });

  @override
  Widget build(BuildContext context) {
    final topUnits = _topEntries(weakUnitCounts);
    final topSections = _topEntries(weakSectionCounts, limit: 5);
    final trendMessages = _trendMessages(topUnits, topSections);
    final supportHints = _supportHints(topUnits, topSections);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: AppColors.screenBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'レポート',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '間違えた単元とセクションから見た支援メモです。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
                ),
                const SizedBox(height: 24),
                _ReportPanel(
                  icon: Icons.flag_rounded,
                  title: '現在の苦手',
                  children: topUnits.isEmpty
                      ? const [_ReportMessage('まだ苦手データは保存されていません。')]
                      : topUnits
                            .map(
                              (entry) => _ReportMessage(
                                '${WeakSignalMapper.unitLabel(entry.key)}: ${entry.value}回',
                              ),
                            )
                            .toList(),
                ),
                const SizedBox(height: 14),
                _ReportPanel(
                  icon: Icons.bar_chart_rounded,
                  title: 'つまずきの記録',
                  children: topSections.isEmpty
                      ? const [
                          _ReportMessage('まだ記録がありません。算数チェックや復習をすると表示されます。'),
                        ]
                      : [
                          const _MiniSectionTitle('間違えたセクション'),
                          _CountBars(
                            entries: topSections,
                            labelFor: WeakSignalMapper.sectionLabel,
                            color: const Color(0xFF2563EB),
                          ),
                        ],
                ),
                const SizedBox(height: 14),
                _ReportPanel(
                  icon: Icons.trending_up_rounded,
                  title: 'つまずきの傾向',
                  children: trendMessages.map(_ReportMessage.new).toList(),
                ),
                const SizedBox(height: 14),
                _ReportPanel(
                  icon: Icons.volunteer_activism_rounded,
                  title: '支援のヒント',
                  children: supportHints.map(_ReportMessage.new).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<MapEntry<String, int>> _topEntries(
    Map<String, int> counts, {
    int limit = 5,
  }) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  List<String> _trendMessages(
    List<MapEntry<String, int>> topUnits,
    List<MapEntry<String, int>> topSections,
  ) {
    final messages = <String>[];
    final unitKeys = topUnits.map((entry) => entry.key).toSet();
    final sectionTitles = topSections
        .map((entry) => WeakSignalMapper.sectionLabel(entry.key))
        .toSet();

    if (unitKeys.contains('division') ||
        sectionTitles.any((title) => title.contains('分ける'))) {
      messages.add('「等しく」「ずつ」「分ける」などの学校日本語を確認するとよさそうです。');
    }
    if (unitKeys.contains('remainder') ||
        sectionTitles.any((title) => title.contains('あまり'))) {
      messages.add('あまりのあるわり算で、商とあまりの両方を確かめる必要がある場面が多いです。');
    }
    if (unitKeys.contains('time') || sectionTitles.contains('短い時間')) {
      messages.add('時こくと時間の進み方・経過時間でつまずいている可能性があります。');
    }
    if (unitKeys.contains('length') || sectionTitles.contains('キロメートル')) {
      messages.add('長さの単位（cm・m・km）の理解を確かめるとよさそうです。');
    }
    if (unitKeys.contains('weight') ||
        sectionTitles.any((title) => title.contains('グラム') || title.contains('トン'))) {
      messages.add('重さの単位（g・kg・t）の理解を確かめるとよさそうです。');
    }

    if (messages.isEmpty && (unitKeys.isNotEmpty || sectionTitles.isNotEmpty)) {
      messages.add('間違えた単元やセクションをもとに、似た問題で少しずつ確認するとよさそうです。');
    } else if (messages.isEmpty) {
      messages.add('まだ傾向を判断するためのデータが少ない状態です。');
    }

    return messages;
  }

  List<String> _supportHints(
    List<MapEntry<String, int>> topUnits,
    List<MapEntry<String, int>> topSections,
  ) {
    final hints = <String>[];
    final unitKeys = topUnits.map((entry) => entry.key).toSet();
    final sectionTitles = topSections
        .map((entry) => WeakSignalMapper.sectionLabel(entry.key))
        .toSet();

    if (unitKeys.contains('division') ||
        sectionTitles.any((title) => title.contains('分ける'))) {
      hints.add('具体物や絵を使って、同じ数ずつ分ける場面を作ってから式につなげると効果的です。');
    }
    if (unitKeys.contains('remainder') ||
        sectionTitles.any((title) => title.contains('あまり'))) {
      hints.add('あまりを「切り上げる場面」と「使わない場面」を分けて話すと整理しやすいです。');
    }
    if (unitKeys.contains('time') || sectionTitles.contains('短い時間')) {
      hints.add('時計を動かしながら、開始・終了・かかった時間を指差し確認すると定着しやすいです。');
    }
    if (unitKeys.contains('length') || sectionTitles.contains('キロメートル')) {
      hints.add('1000m=1km の換算を、メートル棒や地図と一緒に確認すると理解しやすいです。');
    }
    if (unitKeys.contains('weight') ||
        sectionTitles.any((title) => title.contains('グラム') || title.contains('トン'))) {
      hints.add('1000g=1kg の換算表を近くに置いてから問題に入ると安心です。');
    }

    if (hints.isEmpty) {
      hints.add('間違えたセクションをもう一度、ゆっくり確認してから次の問題に進むとよさそうです。');
    }

    return hints.take(4).toList();
  }
}

class _MiniSectionTitle extends StatelessWidget {
  final String text;

  const _MiniSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CountBars extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final String Function(String key) labelFor;
  final Color color;

  const _CountBars({
    required this.entries,
    required this.labelFor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = entries.isEmpty ? 1 : entries.first.value;

    return Column(
      children: entries.map((entry) {
        final ratio = maxCount == 0 ? 0.0 : entry.value / maxCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      labelFor(entry.key),
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value}回',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ReportPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ReportPanel({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ReportMessage extends StatelessWidget {
  final String text;

  const _ReportMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 20,
            color: Color(0xFF16A34A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF374151),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
