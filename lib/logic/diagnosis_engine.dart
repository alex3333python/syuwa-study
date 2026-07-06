import '../models/answer_record.dart';
import '../models/question.dart';

class DiagnosisResult {
  final Map<String, int> tagCounts;
  final Map<MistakeReason, int> mistakeReasonCounts;
  final List<String> weakTags;
  final List<int> recommendedLessonIds;
  final MistakeReason? mostCommonMistakeReason;

  const DiagnosisResult({
    required this.tagCounts,
    required this.mistakeReasonCounts,
    required this.weakTags,
    required this.recommendedLessonIds,
    required this.mostCommonMistakeReason,
  });

  bool get hasWeakness => weakTags.isNotEmpty;
}

class DiagnosisEngine {
  static DiagnosisResult analyze(
    List<Question> wrongQuestions, [
    List<AnswerRecord> answerRecords = const [],
  ]) {
    final tagCounts = <String, int>{};
    final mistakeReasonCounts = <MistakeReason, int>{};

    for (final question in wrongQuestions) {
      for (final tag in question.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    for (final record in answerRecords.where((record) => !record.isCorrect)) {
      final reason = record.mistakeReason;
      if (reason == null) continue;
      mistakeReasonCounts[reason] = (mistakeReasonCounts[reason] ?? 0) + 1;
    }

    final weakTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DiagnosisResult(
      tagCounts: tagCounts,
      mistakeReasonCounts: mistakeReasonCounts,
      weakTags: weakTags.map((entry) => entry.key).take(3).toList(),
      recommendedLessonIds: _recommendedLessonIds(tagCounts),
      mostCommonMistakeReason: _mostCommonMistakeReason(mistakeReasonCounts),
    );
  }

  static MistakeReason? _mostCommonMistakeReason(
    Map<MistakeReason, int> counts,
  ) {
    if (counts.isEmpty) return null;

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  static List<int> _recommendedLessonIds(Map<String, int> tagCounts) {
    final recommendations = <int>[];

    if (_hasAny(tagCounts, ['division', 'school_japanese_equally'])) {
      recommendations.add(2);
    }
    if (_hasAny(tagCounts, ['multiplication', 'school_japanese_each'])) {
      recommendations.add(3);
    }
    if (_hasAny(tagCounts, ['subtraction', 'comparison'])) {
      recommendations.add(4);
    }
    if (_hasAny(tagCounts, ['fraction'])) {
      recommendations.add(5);
    }

    if (recommendations.isEmpty && tagCounts.isNotEmpty) {
      recommendations.add(2);
    }

    return recommendations;
  }

  static bool _hasAny(Map<String, int> tagCounts, List<String> tags) {
    return tags.any((tag) => tagCounts.containsKey(tag));
  }
}
