import '../data/mock_data.dart';
import '../logic/diagnosis_engine.dart';
import '../models/lesson.dart';
import '../models/question.dart';

/// Maps wrong answers to diagnostic units and map sections for the report screen.
class WeakSignalMapper {
  WeakSignalMapper._();

  static final Map<int, int> questionIdToLessonId = _buildQuestionIdToLessonId();
  static final Map<int, String> lessonIdToTitle = {
    for (final lesson in mockLessons) lesson.id: lesson.title,
  };

  static Map<int, int> _buildQuestionIdToLessonId() {
    final map = <int, int>{};

    void addFromLesson(Lesson lesson) {
      for (final question in lesson.questions) {
        map[question.id] = lesson.id;
      }
      for (final step in lesson.steps) {
        for (final question in step.questions) {
          map[question.id] = lesson.id;
        }
      }
    }

    for (final lesson in mockLessons) {
      addFromLesson(lesson);
    }

    return map;
  }

  /// Returns one of [diagnosticUnits] ids: division, remainder, time, length, weight.
  static String? diagnosticUnitIdForQuestion(
    Question question, {
    int? sessionLessonId,
  }) {
    if (sessionLessonId != null && sessionLessonId != 1) {
      final fromSession = diagnosticUnitIdForLesson(sessionLessonId);
      if (fromSession != null) return fromSession;
    }

    final normalized = _normalizeUnitId(question.unitId);
    if (normalized != null) return normalized;

    return _inferUnitFromTags(question.tags);
  }

  static String? diagnosticUnitIdForLesson(int lessonId) {
    for (var index = 0; index < learningUnitSectionIds.length; index++) {
      if (learningUnitSectionIds[index].contains(lessonId)) {
        return diagnosticUnits[index].id;
      }
    }
    return null;
  }

  static int? sectionLessonIdForQuestion(
    Question question, {
    int? sessionLessonId,
  }) {
    if (sessionLessonId != null &&
        sessionLessonId > 0 &&
        isReportSection(sessionLessonId)) {
      return sessionLessonId;
    }

    final mappedLessonId = questionIdToLessonId[question.id];
    if (mappedLessonId != null && isReportSection(mappedLessonId)) {
      return mappedLessonId;
    }

    return null;
  }

  static bool isReportSection(int lessonId) {
    return learningUnitSectionsForLesson(lessonId) != null;
  }

  static String unitLabel(String unitId) {
    return diagnosticUnitById(unitId)?.label ?? unitId;
  }

  static String sectionLabel(String lessonIdKey) {
    final lessonId = int.tryParse(lessonIdKey);
    if (lessonId == null) return lessonIdKey;
    return lessonIdToTitle[lessonId] ?? 'セクション';
  }

  static String? _normalizeUnitId(String rawUnitId) {
    switch (rawUnitId.trim()) {
      case 'division':
      case 'grade3_division':
        return 'division';
      case 'remainder':
      case 'grade3_division_remainder':
        return 'remainder';
      case 'time':
      case 'grade3_time':
        return 'time';
      case 'length':
      case 'grade3_length':
        return 'length';
      case 'weight':
      case 'grade3_weight':
        return 'weight';
      case '':
        return null;
      default:
        return diagnosticUnitById(rawUnitId)?.id;
    }
  }

  static String? _inferUnitFromTags(List<String> tags) {
    final tagSet = tags.toSet();

    bool hasAny(Iterable<String> candidates) =>
        candidates.any(tagSet.contains);

    if (hasAny(const [
      'remainder',
      'remainder_calculation',
      'remainder_check',
      'round_up_context',
      'ignore_remainder_context',
      'remainder_usage_choice',
    ])) {
      return 'remainder';
    }
    if (hasAny(const [
      'time',
      'elapsed_time',
      'minutes_after',
      'minutes_before',
      'seconds',
      'across_hour',
      'noon',
      'am_pm',
      'compare_time',
    ])) {
      return 'time';
    }
    if (hasAny(const ['length', 'kilometer', 'ruler', 'tape_measure'])) {
      return 'length';
    }
    if (hasAny(const ['weight', 'gram', 'kilogram', 'ton'])) {
      return 'weight';
    }
    if (hasAny(const [
      'division',
      'equal-sharing',
      'equal_share',
      'measurement-division',
      'no_remainder',
      'multiplication_connection',
      'zero_division',
      'word_problem',
      'school_japanese_equally',
      'school_japanese_each',
    ])) {
      return 'division';
    }

    return null;
  }
}
