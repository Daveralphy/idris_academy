import 'package:idris_academy/models/quiz_model.dart';
import 'package:idris_academy/models/submodule_model.dart';

class ModuleModel {
  final String id;
  final String title;
  final List<SubmoduleModel> submodules;
  final QuizModel? quiz; // A module can have an optional quiz

  ModuleModel({
    required this.id,
    required this.title,
    this.submodules = const [],
    this.quiz,
  });

  // Method to create a copy, useful for updating user-specific progress
  ModuleModel copyWith({
    String? id,
    String? title,
    List<SubmoduleModel>? submodules,
    QuizModel? quiz,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      title: title ?? this.title,
      submodules: submodules ?? this.submodules,
      quiz: quiz ?? this.quiz,
    );
  }
}
