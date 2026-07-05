import '../models/question.dart';

class DiagnosisResult {
  final Map<String, int> tagCounts;
  final List<String> weakTags;
  final List<int> recommendedLessonIds;

  const DiagnosisResult({
    required this.tagCounts,
    required this.weakTags,
    required this.recommendedLessonIds,
  });

  bool get hasWeakness => weakTags.isNotEmpty;
}

class DiagnosisEngine {
  static DiagnosisResult analyze(List<Question> wrongQuestions) {
    final tagCounts = <String, int>{};

    for (final question in wrongQuestions) {
      for (final tag in question.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    final weakTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DiagnosisResult(
      tagCounts: tagCounts,
      weakTags: weakTags.map((entry) => entry.key).take(3).toList(),
      recommendedLessonIds: _recommendedLessonIds(tagCounts),
    );
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

    if (recommendations.isEmpty && tagCounts.isNotEmpty) {
      recommendations.add(2);
    }

    return recommendations;
  }

  static bool _hasAny(Map<String, int> tagCounts, List<String> tags) {
    return tags.any((tag) => tagCounts.containsKey(tag));
  }
}
