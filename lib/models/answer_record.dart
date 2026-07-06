import 'question.dart';

enum MistakeReason { calculation, wording, askedMeaning, unit }

extension MistakeReasonLabel on MistakeReason {
  String get storageValue => name;

  String get label {
    switch (this) {
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

class AnswerRecord {
  final Question question;
  final int selectedAnswer;
  final bool isCorrect;
  final MistakeReason? mistakeReason;

  const AnswerRecord({
    required this.question,
    required this.selectedAnswer,
    required this.isCorrect,
    this.mistakeReason,
  });
}
