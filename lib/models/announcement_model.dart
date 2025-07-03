class AnnouncementModel {
  final String id; // To link to a notification if needed
  final String title;
  final String message;
  final bool isEnabled;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    this.isEnabled = false,
  });
}

