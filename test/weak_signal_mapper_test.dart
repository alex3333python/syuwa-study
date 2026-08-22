import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_syuwa/logic/diagnosis_engine.dart';
import 'package:flutter_syuwa/logic/weak_signal_mapper.dart';
import 'package:flutter_syuwa/models/question.dart';

void main() {
  group('WeakSignalMapper', () {
    test('maps diagnostic unit ids from question unitId', () {
      const question = Question(
        id: 1,
        type: 'multiple-choice',
        unitId: 'division',
        promptSchoolJa: 'test',
        promptEasyJa: 'test',
        choices: ['1'],
        correctAnswer: 0,
        tags: ['division'],
      );

      expect(
        WeakSignalMapper.diagnosticUnitIdForQuestion(question),
        'division',
      );
      expect(WeakSignalMapper.unitLabel('division'), 'わり算');
    });

    test('maps grade3 unit ids to diagnostic units', () {
      const question = Question(
        id: 2,
        type: 'multiple-choice',
        unitId: 'grade3_time',
        promptSchoolJa: 'test',
        promptEasyJa: 'test',
        choices: ['1'],
        correctAnswer: 0,
        tags: ['time'],
      );

      expect(
        WeakSignalMapper.diagnosticUnitIdForQuestion(question),
        'time',
      );
    });

    test('maps lesson ids to units and section titles', () {
      expect(WeakSignalMapper.diagnosticUnitIdForLesson(19), 'time');
      expect(WeakSignalMapper.sectionLabel('19'), '短い時間');
      expect(WeakSignalMapper.isReportSection(19), isTrue);
      expect(WeakSignalMapper.isReportSection(1), isFalse);
    });

    test('uses session lesson id for section recording', () {
      const question = Question(
        id: 999999,
        type: 'multiple-choice',
        unitId: 'grade3_length',
        promptSchoolJa: 'test',
        promptEasyJa: 'test',
        choices: ['1'],
        correctAnswer: 0,
        tags: ['length'],
      );

      expect(
        WeakSignalMapper.sectionLessonIdForQuestion(
          question,
          sessionLessonId: 22,
        ),
        22,
      );
      expect(WeakSignalMapper.sectionLabel('22'), 'キロメートル');
    });

    test('covers all five diagnostic units in order', () {
      expect(
        diagnosticUnits.map((unit) => unit.label).toList(),
        [
          'わり算',
          'あまりのあるわり算',
          '時こくと時間',
          '長さ',
          '重さ',
        ],
      );
    });
  });
}
