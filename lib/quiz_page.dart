// ignore_for_file: unused_import, unused_local_variable

import 'package:flutter/material.dart';
import 'package:idris_academy/models/quiz_attempt_model.dart';
import 'package:idris_academy/models/quiz_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class QuizPage extends StatefulWidget {
  final String courseId;
  final String moduleId;

  const QuizPage({
    super.key,
    required this.courseId,
    required this.moduleId,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  QuizModel? _quiz;
  int _currentQuestionIndex = 0;
  // Map to store selected option index for each question index
  final Map<int, int> _selectedAnswers = {};
  bool _isSubmitted = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<UserService>(context, listen: false);
    final module = userService.getModuleFromCourse(widget.courseId, widget.moduleId);
    if (module?.quiz != null) {
      _quiz = module!.quiz;
    }
  }

  void _selectAnswer(int questionIndex, int optionIndex) {
    if (_isSubmitted) return; // Don't allow changes after submission
    setState(() {
      _selectedAnswers[questionIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quiz!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _submitQuiz() {
    if (_quiz == null) return;
    int correctAnswers = 0;
    for (int i = 0; i < _quiz!.questions.length; i++) {
      final question = _quiz!.questions[i];
      final selectedOptionIndex = _selectedAnswers[i];
      if (selectedOptionIndex != null) {
        if (question.options[selectedOptionIndex].isCorrect) {
          correctAnswers++;
        }
      }
    }
    setState(() {
      _score = correctAnswers;
      _isSubmitted = true;
    });

    // Save the attempt to the user's progress
    final userService = Provider.of<UserService>(context, listen: false);
    userService.saveQuizAttempt(widget.courseId, widget.moduleId, _score, _quiz!.questions.length, _selectedAnswers);
  }

  @override
  Widget build(BuildContext context) {
    if (_quiz == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Quiz not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_quiz!.title),
        // Prevent going back with device back button during quiz
        automaticallyImplyLeading: _isSubmitted,
      ),
      body: _isSubmitted ? _buildResultsView() : _buildQuestionView(),
    );
  }

  Widget _buildQuestionView() {
    final question = _quiz!.questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _quiz!.questions.length - 1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_quiz!.questions.length}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            question.text,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: RadioListTile<int>(
                    title: Text(question.options[index].text),
                    value: index,
                    groupValue: _selectedAnswers[_currentQuestionIndex],
                    onChanged: (value) {
                      if (value != null) {
                        _selectAnswer(_currentQuestionIndex, value);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
              ),
              ElevatedButton(
                onPressed: isLastQuestion ? _submitQuiz : _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(isLastQuestion ? 'Submit' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final totalQuestions = _quiz!.questions.length;
    final percentage = totalQuestions > 0 ? (_score / totalQuestions * 100).round() : 0;
    final userService = Provider.of<UserService>(context, listen: false);
    final pastAttempts = userService.getQuizAttemptsForModule(widget.courseId, widget.moduleId);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Quiz Complete!', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Text(
                  'You Scored',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '$_score / $totalQuestions ($percentage%)',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (pastAttempts.length > 1) ...[
          const SizedBox(height: 24),
          Text('Past Attempts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          // We skip the first attempt because it's the one we just completed.
          ...pastAttempts.skip(1).map((attempt) {
            final attemptPercentage = (attempt.score / attempt.totalQuestions * 100).round();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  'Score: ${attempt.score} / ${attempt.totalQuestions} ($attemptPercentage%)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat.yMMMd().add_jm().format(attempt.timestamp),
                ),
                onTap: () {
                  // TODO: Could add a feature to review the answers of a past attempt.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reviewing past attempts is not yet implemented.')),
                  );
                },
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
        Text('Review Answers', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...List.generate(_quiz!.questions.length, (index) {
          final question = _quiz!.questions[index];
          final selectedAnswerIndex = _selectedAnswers[index];
          final correctAnswerIndex = question.options.indexWhere((o) => o.isCorrect);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${index + 1}: ${question.text}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...List.generate(question.options.length, (optionIndex) {
                    final option = question.options[optionIndex];
                    final isSelected = selectedAnswerIndex == optionIndex;
                    final isCorrect = option.isCorrect;

                    Icon icon;
                    Color color;

                    if (isCorrect) {
                      icon = const Icon(Icons.check_circle, color: Colors.green);
                      color = Colors.green;
                    } else if (isSelected && !isCorrect) {
                      icon = const Icon(Icons.cancel, color: Colors.red);
                      color = Colors.red;
                    } else {
                      icon = const Icon(Icons.radio_button_unchecked, color: Colors.grey);
                      color = Theme.of(context).textTheme.bodyLarge!.color!;
                    }

                    return ListTile(
                      dense: true,
                      leading: icon,
                      title: Text(option.text, style: TextStyle(color: color, fontWeight: isSelected || isCorrect ? FontWeight.bold : FontWeight.normal)),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Course'),
        ),
      ],
    );
  }
}
