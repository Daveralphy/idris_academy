import 'package:idris_academy/models/module_model.dart';

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final List<String> tags;
  final String teacherName;
  final List<ModuleModel> modules;

  // --- New fields for assessment ---
  final bool hasGradedQuizzes;
  final bool hasFinalExam;

  // --- New fields for certification ---
  final bool hasCertificate;
  final int? certificatePassingGrade; // e.g., 80 for 80%

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
    // --- Initialize new fields ---
    this.hasGradedQuizzes = false,
    this.hasFinalExam = false,
    // --- Initialize new fields ---
    this.hasCertificate = false, // Default to false
    this.certificatePassingGrade,
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
    String? teacherName,
    List<ModuleModel>? modules,
    bool? hasCertificate,
    bool? hasGradedQuizzes,
    bool? hasFinalExam,
    int? certificatePassingGrade,
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
      teacherName: teacherName ?? this.teacherName,
      modules: modules ?? this.modules,
      hasCertificate: hasCertificate ?? this.hasCertificate,
      hasGradedQuizzes: hasGradedQuizzes ?? this.hasGradedQuizzes,
      hasFinalExam: hasFinalExam ?? this.hasFinalExam,
      certificatePassingGrade: certificatePassingGrade ?? this.certificatePassingGrade,
      progress: progress ?? this.progress,
      lastAccessedSubmoduleId: lastAccessedSubmoduleId ?? this.lastAccessedSubmoduleId,
      isEnrolled: isEnrolled ?? this.isEnrolled,
    );
  }
}