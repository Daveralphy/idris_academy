enum NotificationType {
  courseUpdate,
  message,
  announcement,
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? sender;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.sender,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}