import 'package:idris_academy/models/comment_model.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfilePictureUrl;
  final DateTime timestamp;
  final String text;
  final String? imageUrl;
  final String? videoUrl;
  final int likeCount;
  final List<CommentModel> comments;
  final bool isLikedByUser; // To track if the current user has liked it

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorProfilePictureUrl,
    required this.timestamp,
    required this.text,
    this.imageUrl,
    this.videoUrl,
    this.likeCount = 0,
    this.comments = const [],
    this.isLikedByUser = false,
  });
}
