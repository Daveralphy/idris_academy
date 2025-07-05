import 'package:idris_academy/models/submodule_model.dart';

class ModuleModel {
  final String id;
  final String title;
  final List<SubmoduleModel> submodules;

  ModuleModel({
    required this.id,
    required this.title,
    required this.submodules,
  });

  // Method to create a copy, useful for updating user-specific progress
  ModuleModel copyWith({List<SubmoduleModel>? submodules, required String title}) {
    return ModuleModel(id: id, title: title, submodules: submodules ?? this.submodules);
  }
}

