import 'package:flutter/material.dart';

import '../models/answer_record.dart';

class ReportScreen extends StatelessWidget {
  final Map<String, int> weakTagCounts;
  final Map<String, int> weakReasonCounts;

  const ReportScreen({
    super.key,
    required this.weakTagCounts,
    required this.weakReasonCounts,
  });

  @override
  Widget build(BuildContext context) {
    final topTags = _topEntries(weakTagCounts);
    final topThreeTags = _topEntries(weakTagCounts, limit: 3);
    final topThreeReasons = _topEntries(weakReasonCounts, limit: 3);
    final topReason = _topReason();
    final trendMessages = _trendMessages(topTags, topReason);
    final supportHints = _supportHints(topTags, topReason);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '先生・保護者向けミニレポート',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '正誤、問題タグ、本人が選んだ「むずかしかった理由」から見た支援メモです。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
                ),
                const SizedBox(height: 24),
                _ReportPanel(
                  icon: Icons.flag_rounded,
                  title: '現在の苦手',
                  children: topTags.isEmpty
                      ? const [_ReportMessage('まだ苦手データは保存されていません。')]
                      : topTags
                            .map(
                              (entry) => _ReportMessage(
                                '${_tagLabel(entry.key)}: ${entry.value}回',
                              ),
                            )
                            .toList(),
                ),
                const SizedBox(height: 14),
                _ReportPanel(
                  icon: Icons.bar_chart_rounded,
                  title: 'つまずきの記録',
                  children: topThreeTags.isEmpty && topThreeReasons.isEmpty
                      ? const [
                          _ReportMessage('まだ記録がありません。算数チェックや復習をすると表示されます。'),
                        ]
                      : [
                          if (topThreeTags.isNotEmpty) ...[
                            const _MiniSectionTitle('苦手タグ 上位3件'),
                            _CountBars(
                              entries: topThreeTags,
                              labelFor: _tagLabel,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (topThreeReasons.isNotEmpty) ...[
                            const _MiniSectionTitle('むずかしかった理由 上位3件'),
                            _CountBars(
                              entries: topThreeReasons,
                              labelFor: _reasonLabel,
                              color: Color(0xFFF97316),
                            ),
                          ],
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

  MistakeReason? _topReason() {
    if (weakReasonCounts.isEmpty) return null;

    final entries = weakReasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topKey = entries.first.key;

    for (final reason in MistakeReason.values) {
      if (reason.storageValue == topKey) {
        return reason;
      }
    }
    return null;
  }

  List<String> _trendMessages(
    List<MapEntry<String, int>> topTags,
    MistakeReason? topReason,
  ) {
    final messages = <String>[];
    final topTagKeys = topTags.map((entry) => entry.key).toSet();

    if (_isTopTag('word_problem', topTags)) {
      messages.add('計算そのものよりも、問題文の読み取りでつまずいている可能性があります。');
    }
    if (_isTopTag('equal_share', topTags) ||
        _isTopTag('school_japanese_equally', topTags)) {
      messages.add('「等しく」「ずつ」「分ける」などの学校日本語を確認するとよさそうです。');
    }
    if (topReason == MistakeReason.wording) {
      messages.add('本人の選択では、問題文の言葉がわからなかった場面が多く見られます。');
    }

    if (messages.isEmpty && topTagKeys.isNotEmpty) {
      messages.add('保存された苦手タグをもとに、似た問題で少しずつ確認するとよさそうです。');
    } else if (messages.isEmpty) {
      messages.add('まだ傾向を判断するためのデータが少ない状態です。');
    }

    return messages;
  }

  List<String> _supportHints(
    List<MapEntry<String, int>> topTags,
    MistakeReason? topReason,
  ) {
    final hints = <String>[];

    if (topReason == MistakeReason.wording) {
      hints.add('日本語語彙支援を優先し、問題文の大事な言葉を先に確認してから計算に入るとよさそうです。');
    }
    if (_hasTag('word_problem', topTags)) {
      hints.add('「何を聞かれているか」を最後の一文から一緒に確認すると、式を選びやすくなります。');
    }
    if (_hasTag('equal_share', topTags) ||
        _hasTag('school_japanese_equally', topTags)) {
      hints.add('具体物や絵を使って、同じ数ずつ分ける場面を作ってから式につなげると効果的です。');
    }

    if (hints.isEmpty) {
      hints.add('学習後に、間違えた理由を本人に選んでもらうことで、支援の方向が見えやすくなります。');
    }

    return hints;
  }

  bool _isTopTag(String tag, List<MapEntry<String, int>> topTags) {
    if (topTags.isEmpty) return false;
    final topCount = topTags.first.value;
    return topTags.any((entry) => entry.key == tag && entry.value == topCount);
  }

  bool _hasTag(String tag, List<MapEntry<String, int>> topTags) {
    return topTags.any((entry) => entry.key == tag);
  }

  String _tagLabel(String tag) {
    switch (tag) {
      case 'division':
        return 'わり算';
      case 'word_problem':
        return '文章題';
      case 'equal_share':
      case 'school_japanese_equally':
        return '等しく分ける言葉';
      case 'multiplication':
        return 'かけ算';
      case 'subtraction':
        return 'ひき算';
      case 'comparison':
        return 'くらべる問題';
      case 'fraction':
        return '分数';
      default:
        return tag;
    }
  }

  String _reasonLabel(String reasonKey) {
    for (final reason in MistakeReason.values) {
      if (reason.storageValue == reasonKey) {
        switch (reason) {
          case MistakeReason.calculation:
            return '計算がわからなかった';
          case MistakeReason.wording:
            return '問題文の言葉がわからなかった';
          case MistakeReason.askedMeaning:
            return '何を聞かれているかわからなかった';
          case MistakeReason.unit:
            return '単位がわからなかった';
        }
      }
    }
    return reasonKey;
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
