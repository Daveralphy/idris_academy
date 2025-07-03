import 'package:idris_academy/models/module_model.dart';

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final List<String> tags;
  final List<ModuleModel> modules; // New: Course content structure

  // User-specific progress fields (can be initialized with defaults)
  double progress; // Overall course progress (0.0 to 1.0)
  String lastAccessed; // Last accessed submodule title or lesson
  bool isEnrolled; // New: To track if the user is enrolled

  CourseModel({
    required this.id,
    required this.title,
    this.description = '',
    this.thumbnailUrl = '',
    this.tags = const [],
    this.modules = const [], // Default to empty modules
    this.progress = 0.0,
    this.lastAccessed = '',
    this.isEnrolled = false, // Default enrollment status
  });

  // Method to create a copy, useful for updating user-specific progress
  CourseModel copyWith({
    double? progress,
    String? lastAccessed,
    bool? isEnrolled,
    List<ModuleModel>? modules,
  }) {
    return CourseModel(
      id: id,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      tags: tags,
      modules: modules ?? this.modules,
      progress: progress ?? this.progress,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isEnrolled: isEnrolled ?? this.isEnrolled,
    );
  }
}