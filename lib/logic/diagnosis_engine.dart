import '../models/answer_record.dart';
import '../models/question.dart';

/// 算数チェックが対象にする実装済み学習単元。
class DiagnosticUnitInfo {
  final String id;
  final String label;
  final int entryLessonId;

  const DiagnosticUnitInfo({
    required this.id,
    required this.label,
    required this.entryLessonId,
  });
}

const List<DiagnosticUnitInfo> diagnosticUnits = [
  DiagnosticUnitInfo(id: 'division', label: 'わり算', entryLessonId: 7),
  DiagnosticUnitInfo(
    id: 'remainder',
    label: 'あまりのあるわり算',
    entryLessonId: 12,
  ),
  DiagnosticUnitInfo(id: 'time', label: '時こくと時間', entryLessonId: 18),
  DiagnosticUnitInfo(id: 'length', label: '長さ', entryLessonId: 21),
  DiagnosticUnitInfo(id: 'weight', label: '重さ', entryLessonId: 23),
];

DiagnosticUnitInfo? diagnosticUnitById(String unitId) {
  for (final unit in diagnosticUnits) {
    if (unit.id == unitId) return unit;
  }
  return null;
}

/// 単元ごとの理解度（正答数 / 出題数）。
class UnitDiagnosisScore {
  final String unitId;
  final String label;
  final int correct;
  final int total;
  final int entryLessonId;

  const UnitDiagnosisScore({
    required this.unitId,
    required this.label,
    required this.correct,
    required this.total,
    required this.entryLessonId,
  });

  double get rate => total == 0 ? 1.0 : correct / total;

  bool get isStrong => total > 0 && correct == total;

  bool get isWeak => total > 0 && correct < total;

  String get summary => '$correct / $total';
}

class DiagnosisResult {
  final Map<String, int> tagCounts;
  final Map<MistakeReason, int> mistakeReasonCounts;
  final List<String> weakTags;
  final List<int> recommendedLessonIds;
  final MistakeReason? mostCommonMistakeReason;
  final List<UnitDiagnosisScore> unitScores;

  const DiagnosisResult({
    required this.tagCounts,
    required this.mistakeReasonCounts,
    required this.weakTags,
    required this.recommendedLessonIds,
    required this.mostCommonMistakeReason,
    this.unitScores = const [],
  });

  bool get hasWeakness =>
      weakTags.isNotEmpty || unitScores.any((score) => score.isWeak);

  List<UnitDiagnosisScore> get strongUnits =>
      unitScores.where((score) => score.isStrong).toList();

  List<UnitDiagnosisScore> get weakUnits {
    final weak = unitScores.where((score) => score.isWeak).toList()
      ..sort((a, b) {
        final byRate = a.rate.compareTo(b.rate);
        if (byRate != 0) return byRate;
        return a.correct.compareTo(b.correct);
      });
    return weak;
  }
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
      final unitId = question.unitId.trim();
      if (unitId.isNotEmpty) {
        tagCounts[unitId] = (tagCounts[unitId] ?? 0) + 1;
      }
    }

    for (final record in answerRecords.where((record) => !record.isCorrect)) {
      final reason = record.mistakeReason;
      if (reason == null) continue;
      mistakeReasonCounts[reason] = (mistakeReasonCounts[reason] ?? 0) + 1;
    }

    // Infer language / meaning / unit struggles from wrong question tags
    // when the learner did not pick an explicit MistakeReason.
    _inferSupportSignals(wrongQuestions, mistakeReasonCounts);

    final unitScores = _buildUnitScores(answerRecords, wrongQuestions);
    final weakTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return DiagnosisResult(
      tagCounts: tagCounts,
      mistakeReasonCounts: mistakeReasonCounts,
      weakTags: weakTags.map((entry) => entry.key).take(5).toList(),
      recommendedLessonIds: _recommendedLessonIds(unitScores, tagCounts),
      mostCommonMistakeReason: _mostCommonMistakeReason(mistakeReasonCounts),
      unitScores: unitScores,
    );
  }

  static List<UnitDiagnosisScore> _buildUnitScores(
    List<AnswerRecord> answerRecords,
    List<Question> wrongQuestions,
  ) {
    final correctByUnit = <String, int>{};
    final totalByUnit = <String, int>{};

    void count(Question question, {required bool isCorrect}) {
      final unitId = question.unitId.trim();
      if (unitId.isEmpty || diagnosticUnitById(unitId) == null) return;
      totalByUnit[unitId] = (totalByUnit[unitId] ?? 0) + 1;
      if (isCorrect) {
        correctByUnit[unitId] = (correctByUnit[unitId] ?? 0) + 1;
      }
    }

    if (answerRecords.isNotEmpty) {
      for (final record in answerRecords) {
        count(record.question, isCorrect: record.isCorrect);
      }
    } else {
      for (final question in wrongQuestions) {
        count(question, isCorrect: false);
      }
    }

    return [
      for (final unit in diagnosticUnits)
        UnitDiagnosisScore(
          unitId: unit.id,
          label: unit.label,
          correct: correctByUnit[unit.id] ?? 0,
          total: totalByUnit[unit.id] ?? 0,
          entryLessonId: unit.entryLessonId,
        ),
    ];
  }

  static void _inferSupportSignals(
    List<Question> wrongQuestions,
    Map<MistakeReason, int> mistakeReasonCounts,
  ) {
    for (final question in wrongQuestions) {
      final tags = question.tags.toSet();
      if (tags.contains('unit') ||
          tags.contains('kilometer') ||
          tags.contains('kilogram') ||
          tags.contains('gram')) {
        mistakeReasonCounts[MistakeReason.unit] =
            (mistakeReasonCounts[MistakeReason.unit] ?? 0) + 1;
      }
      if (tags.contains('word_problem') ||
          tags.any((tag) => tag.startsWith('school_japanese_'))) {
        mistakeReasonCounts[MistakeReason.wording] =
            (mistakeReasonCounts[MistakeReason.wording] ?? 0) + 1;
      }
      if (tags.contains('asked_meaning') ||
          tags.contains('round_up_context') ||
          tags.contains('ignore_remainder_context')) {
        mistakeReasonCounts[MistakeReason.askedMeaning] =
            (mistakeReasonCounts[MistakeReason.askedMeaning] ?? 0) + 1;
      }
      if (tags.contains('remainder_calculation') ||
          tags.contains('elapsed_time') ||
          tags.contains('minutes_after') ||
          tags.contains('equal-sharing') ||
          tags.contains('measurement-division')) {
        mistakeReasonCounts[MistakeReason.calculation] =
            (mistakeReasonCounts[MistakeReason.calculation] ?? 0) + 1;
      }
    }
  }

  static MistakeReason? _mostCommonMistakeReason(
    Map<MistakeReason, int> counts,
  ) {
    if (counts.isEmpty) return null;

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  static List<int> _recommendedLessonIds(
    List<UnitDiagnosisScore> unitScores,
    Map<String, int> tagCounts,
  ) {
    final weak = unitScores.where((score) => score.isWeak).toList()
      ..sort((a, b) {
        final byRate = a.rate.compareTo(b.rate);
        if (byRate != 0) return byRate;
        return a.correct.compareTo(b.correct);
      });

    if (weak.isNotEmpty) {
      return weak.map((score) => score.entryLessonId).take(3).toList();
    }

    // Fallback for legacy / incomplete records without unit scores.
    if (_hasAny(tagCounts, ['division', 'equal-sharing', 'school_japanese_equally'])) {
      return const [7];
    }
    if (_hasAny(tagCounts, ['remainder', 'remainder_calculation'])) {
      return const [12];
    }
    if (_hasAny(tagCounts, ['time', 'elapsed_time', 'minutes_after'])) {
      return const [18];
    }
    if (_hasAny(tagCounts, ['length', 'kilometer'])) {
      return const [21];
    }
    if (_hasAny(tagCounts, ['weight', 'kilogram', 'gram'])) {
      return const [23];
    }
    if (tagCounts.isNotEmpty) {
      return const [7];
    }
    return const [];
  }

  static bool _hasAny(Map<String, int> tagCounts, List<String> tags) {
    return tags.any((tag) => tagCounts.containsKey(tag));
  }
}
