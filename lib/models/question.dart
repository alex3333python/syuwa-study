class Question {
  final int id;
  final String type;
  final String question;
  final String signDescription;
  final List<String> options;
  final int correctAnswer;
  final String? imageUrl;

  const Question({
    required this.id,
    required this.type,
    required this.question,
    required this.signDescription,
    required this.options,
    required this.correctAnswer,
    this.imageUrl,
  });
}