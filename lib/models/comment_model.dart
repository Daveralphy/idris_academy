class CommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfilePictureUrl;
  final DateTime timestamp;
  final String text;

  CommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfilePictureUrl,
    required this.timestamp,
    required this.text,
  });
}
