import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_syuwa/data/diagnostic_questions.dart';
import 'package:flutter_syuwa/logic/diagnosis_engine.dart';
import 'package:flutter_syuwa/models/answer_record.dart';
import 'package:flutter_syuwa/models/question.dart';

void main() {
  test('diagnostic bank covers all five implemented units twice', () {
    expect(diagnosticQuestions.length, 10);

    final byUnit = <String, int>{};
    for (final question in diagnosticQuestions) {
      byUnit[question.unitId] = (byUnit[question.unitId] ?? 0) + 1;
    }

    expect(byUnit['division'], 2);
    expect(byUnit['remainder'], 2);
    expect(byUnit['time'], 2);
    expect(byUnit['length'], 2);
    expect(byUnit['weight'], 2);
  });

  test('diagnosis recommends weakest units first', () {
    AnswerRecord mark(Question question, {required bool correct}) {
      final wrongIndex =
          (question.correctAnswer + 1) % question.choices.length;
      return AnswerRecord(
        question: question,
        selectedAnswer: correct ? question.correctAnswer : wrongIndex,
        isCorrect: correct,
      );
    }

    final records = <AnswerRecord>[
      for (final question in diagnosticQuestions)
        if (question.unitId == 'time')
          mark(question, correct: false)
        else if (question.id == 1004 || question.id == 1010)
          mark(question, correct: false)
        else
          mark(question, correct: true),
    ];

    final wrong = records
        .where((record) => !record.isCorrect)
        .map((record) => record.question)
        .toList();
    final result = DiagnosisEngine.analyze(wrong, records);

    expect(result.unitScores.length, 5);
    expect(
      result.unitScores.firstWhere((score) => score.unitId == 'division').summary,
      '2 / 2',
    );
    expect(
      result.unitScores.firstWhere((score) => score.unitId == 'time').summary,
      '0 / 2',
    );
    expect(
      result.unitScores
          .firstWhere((score) => score.unitId == 'remainder')
          .summary,
      '1 / 2',
    );
    expect(
      result.unitScores.firstWhere((score) => score.unitId == 'weight').summary,
      '1 / 2',
    );

    // Weakest first: time 0/2, then remainder/weight 1/2.
    expect(result.recommendedLessonIds.first, 18);
    expect(result.recommendedLessonIds, containsAll(<int>[12, 23]));
    expect(
      result.strongUnits.map((score) => score.unitId).toSet(),
      containsAll(<String>['division', 'length']),
    );
  });

  test('after diagnosis, only each unit entry is unlocked', () {
    expect(
      shouldLessonBeLocked(
        lessonId: 1,
        diagnosisCompleted: false,
        isCompleted: (_) => false,
      ),
      isFalse,
    );
    expect(
      shouldLessonBeLocked(
        lessonId: 18,
        diagnosisCompleted: false,
        isCompleted: (_) => false,
      ),
      isTrue,
    );
    expect(
      shouldLessonBeLocked(
        lessonId: 7,
        diagnosisCompleted: true,
        isCompleted: (_) => false,
      ),
      isFalse,
    );
    expect(
      shouldLessonBeLocked(
        lessonId: 18,
        diagnosisCompleted: true,
        isCompleted: (_) => false,
      ),
      isFalse,
    );
    expect(
      shouldLessonBeLocked(
        lessonId: 23,
        diagnosisCompleted: true,
        isCompleted: (_) => false,
      ),
      isFalse,
    );
    // Later sections in the same unit stay locked until the previous one is done.
    expect(
      shouldLessonBeLocked(
        lessonId: 8,
        diagnosisCompleted: true,
        isCompleted: (_) => false,
      ),
      isTrue,
    );
    expect(
      shouldLessonBeLocked(
        lessonId: 8,
        diagnosisCompleted: true,
        isCompleted: (id) => id == 7,
      ),
      isFalse,
    );
    expect(
      shouldLessonBeLocked(
        lessonId: 19,
        diagnosisCompleted: true,
        isCompleted: (_) => false,
      ),
      isTrue,
    );
  });
}
