class QuizModel {
  final String id;
  final String title;
  final List<QuestionModel> questions;

  QuizModel({
    required this.id,
    required this.title,
    this.questions = const [],
  });
}

class QuestionModel {
  final String id;
  final String text;
  final List<OptionModel> options;

  QuestionModel({
    required this.id,
    required this.text,
    required this.options,
  });
}

class OptionModel {
  final String text;
  final bool isCorrect;

  OptionModel({
    required this.text,
    this.isCorrect = false,
  });
}

