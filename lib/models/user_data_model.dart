import 'package:idris_academy/models/course_model.dart';
import 'package:idris_academy/models/notification_model.dart';
import 'package:idris_academy/models/chat_message_model.dart';
import 'package:idris_academy/models/quiz_attempt_model.dart';

/// Represents all the dynamic data associated with a single user.
class UserData {
  List<CourseModel> inProgressCourses;
  List<CourseModel> recommendedCourses;
  Map<String, String> achievements;
  int notificationCount;
  List<NotificationModel> notifications;
  String paymentPlan;
  List<ChatMessageModel> supportChatHistory;
  List<QuizAttemptModel> quizAttempts; // New field

  UserData({
    required this.inProgressCourses,
    required this.recommendedCourses,
    required this.achievements,
    required this.notificationCount,
    required this.notifications,
    required this.paymentPlan,
    required this.supportChatHistory,
    this.quizAttempts = const [], // Initialize with empty list
  });
}