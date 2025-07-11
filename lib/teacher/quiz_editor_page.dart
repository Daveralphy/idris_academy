// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:idris_academy/models/module_model.dart';
import 'package:idris_academy/models/quiz_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:provider/provider.dart';

class QuizEditorPage extends StatefulWidget {
  final String courseId;
  final String moduleId;

  const QuizEditorPage({
    super.key,
    required this.courseId,
    required this.moduleId,
  });

  @override
  State<QuizEditorPage> createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage> {
  late QuizModel _quiz;
  late TextEditingController _titleController;
  bool _isNewQuiz = false;

  @override
  void initState() {
    super.initState();
    final module = Provider.of<UserService>(context, listen: false).getModuleFromCourse(widget.courseId, widget.moduleId);

    if (module?.quiz == null) {
      _isNewQuiz = true;
      _quiz = QuizModel(
        id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
        title: '${module?.title ?? 'Module'} Quiz',
        questions: [],
      );
    } else {
      // Create a deep copy to avoid modifying the original object until save.
      final originalQuiz = module!.quiz!;
      _quiz = QuizModel(
        id: originalQuiz.id,
        title: originalQuiz.title,
        questions: originalQuiz.questions.map((q) => QuestionModel(
          id: q.id,
          text: q.text,
          options: q.options.map((o) => OptionModel(text: o.text, isCorrect: o.isCorrect)).toList(),
        )).toList(),
      );
    }

    _titleController = TextEditingController(text: _quiz.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveQuiz() {
    final updatedQuiz = QuizModel(
      id: _quiz.id,
      title: _titleController.text,
      questions: _quiz.questions,
    );
    Provider.of<UserService>(context, listen: false).addOrUpdateQuizForModule(widget.courseId, widget.moduleId, updatedQuiz);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz saved successfully!'), backgroundColor: Colors.green),
    );
  }

  void _deleteQuiz() async {
     final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Quiz?'),
        content: const Text('Are you sure you want to permanently delete this quiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      Provider.of<UserService>(context, listen: false).deleteQuizFromModule(widget.courseId, widget.moduleId);
      Navigator.of(context).pop();
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz deleted.'), backgroundColor: Colors.green),
      );
    }
  }

  void _showQuestionDialog({QuestionModel? existingQuestion}) {
    final isEditing = existingQuestion != null;
    final questionTextController = TextEditingController(text: existingQuestion?.text ?? '');
    List<TextEditingController> optionControllers = existingQuestion?.options.map((o) => TextEditingController(text: o.text)).toList() ?? [TextEditingController(), TextEditingController()];
    int? correctOptionIndex = existingQuestion?.options.indexWhere((o) => o.isCorrect);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Question' : 'Add Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionTextController,
                      decoration: const InputDecoration(labelText: 'Question Text'),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List.generate(optionControllers.length, (index) {
                      return Row(
                        children: [
                          Radio<int>(
                            value: index,
                            groupValue: correctOptionIndex,
                            onChanged: (value) => setDialogState(() => correctOptionIndex = value),
                          ),
                          Expanded(child: TextField(controller: optionControllers[index])),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: optionControllers.length > 2
                                ? () => setDialogState(() {
                                      optionControllers.removeAt(index);
                                      if (correctOptionIndex == index) correctOptionIndex = null;
                                      if (correctOptionIndex != null && correctOptionIndex! > index) correctOptionIndex = correctOptionIndex! - 1;
                                    })
                                : null,
                          ),
                        ],
                      );
                    }),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Option'),
                      onPressed: () => setDialogState(() => optionControllers.add(TextEditingController())),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final newQuestion = QuestionModel(
                      id: existingQuestion?.id ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
                      text: questionTextController.text,
                      options: List.generate(optionControllers.length, (index) => OptionModel(
                        text: optionControllers[index].text,
                        isCorrect: correctOptionIndex == index,
                      )),
                    );
                    setState(() {
                      if (isEditing) {
                        final qIndex = _quiz.questions.indexWhere((q) => q.id == newQuestion.id);
                        _quiz.questions[qIndex] = newQuestion;
                      } else {
                        _quiz.questions.add(newQuestion);
                      }
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Editor'),
        actions: [
          if (!_isNewQuiz)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteQuiz,
              tooltip: 'Delete Quiz',
            ),
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _saveQuiz,
            tooltip: 'Save Quiz',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Quiz Title',
              border: OutlineInputBorder(),
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Questions', style: Theme.of(context).textTheme.titleLarge),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                onPressed: () => _showQuestionDialog(),
              ),
            ],
          ),
          const Divider(),
          if (_quiz.questions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48.0),
              child: Center(
                child: Text(
                  'No questions yet.\nTap "Add" to create one.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quiz.questions.length,
              itemBuilder: (context, index) {
                final question = _quiz.questions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(question.text),
                    subtitle: Text('${question.options.length} options'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showQuestionDialog(existingQuestion: question),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                          onPressed: () {
                            setState(() {
                              _quiz.questions.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuestionDialog(),
        tooltip: 'Add Question',
        child: const Icon(Icons.add),
      ),
    );
  }
}

