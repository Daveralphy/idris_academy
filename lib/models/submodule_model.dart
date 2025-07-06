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
  SubmoduleModel copyWith({
    String? title,
    String? transcript,
    ContentType? contentType,
    String? contentUrl,
    bool? isCompleted,
  }) {
    return SubmoduleModel(
      id: id,
      title: title ?? this.title,
      contentType: contentType ?? this.contentType,
      contentUrl: contentUrl ?? this.contentUrl,
      transcript: transcript ?? this.transcript,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
