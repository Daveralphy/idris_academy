class QuizAttemptModel {
  final String quizId;
  final DateTime timestamp;
  final int score;
  final int totalQuestions;
  final Map<int, int> selectedAnswers; // questionIndex -> optionIndex

  QuizAttemptModel({
    required this.quizId,
    required this.timestamp,
    required this.score,
    required this.totalQuestions,
    required this.selectedAnswers,
  });
}

