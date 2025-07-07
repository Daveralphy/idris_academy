import 'package:idris_academy/models/module_model.dart';

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final List<String> tags;
  final List<ModuleModel> modules;
  final String teacherName;

  // User-specific progress fields
  final double progress;
  final String? lastAccessedSubmoduleId; // Changed from lastAccessed
  final bool isEnrolled;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.tags,
    required this.teacherName,
    this.modules = const [],
    this.progress = 0.0,
    this.lastAccessedSubmoduleId,
    this.isEnrolled = false,
  });

  // Method to create a copy with updated values.
  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    List<String>? tags,
    List<ModuleModel>? modules,
    String? teacherName,
    double? progress,
    String? lastAccessedSubmoduleId,
    bool? isEnrolled,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      tags: tags ?? this.tags,
      modules: modules ?? this.modules,
      teacherName: teacherName ?? this.teacherName,
      progress: progress ?? this.progress,
      lastAccessedSubmoduleId: lastAccessedSubmoduleId ?? this.lastAccessedSubmoduleId,
      isEnrolled: isEnrolled ?? this.isEnrolled,
    );
  }
}