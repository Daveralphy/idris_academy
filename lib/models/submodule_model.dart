enum ContentType { youtubeVideo, networkVideo, image, text }

class SubmoduleModel {
  final String id;
  final String title;
  final ContentType contentType;
  final String contentUrl; // URL to video (YouTube, TikTok) or text content
  final String transcript; // Transcript for video, or full text for text content
  bool isCompleted; // User-specific completion status

  SubmoduleModel({
    required this.id,
    required this.title,
    required this.contentType,
    required this.contentUrl,
    this.transcript = '',
    this.isCompleted = false,
  });

  // Method to create a copy, useful for updating user-specific progress
  SubmoduleModel copyWith({bool? isCompleted, required String title, required String transcript}) {
    return SubmoduleModel(
      id: id,
      title: title,
      contentType: contentType,
      contentUrl: contentUrl,
      transcript: transcript,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
