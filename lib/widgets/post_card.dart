import 'package:flutter/material.dart';
import 'package:idris_academy/models/post_model.dart';
import 'package:intl/intl.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimestamp(post.timestamp);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostHeader(context, timeAgo),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(post.text, style: textTheme.bodyLarge),
          ),
          if (post.imageUrl != null) _buildPostImage(context),
          _buildPostActions(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context, String timeAgo) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: post.authorProfilePictureUrl != null && post.authorProfilePictureUrl!.startsWith('http')
                ? NetworkImage(post.authorProfilePictureUrl!)
                : null,
            child: post.authorProfilePictureUrl == null || !post.authorProfilePictureUrl!.startsWith('http')
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(timeAgo, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More options coming soon!')),
              );
            },
            tooltip: 'More options',
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Image.network(
        post.imageUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 250,
            color: Theme.of(context).colorScheme.surface,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 250,
            color: Theme.of(context).colorScheme.surface,
            child: const Center(child: Icon(Icons.image_not_supported)),
          );
        },
      ),
    );
  }

  Widget _buildPostActions(BuildContext context, ColorScheme colorScheme) {
    final hasStats = post.likeCount > 0 || post.comments.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          if (hasStats)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (post.likeCount > 0)
                    Text('${post.likeCount} likes', style: Theme.of(context).textTheme.bodySmall),
                  if (post.comments.isNotEmpty)
                    Text('${post.comments.length} comments', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionButton(context, icon: post.isLikedByUser ? Icons.thumb_up : Icons.thumb_up_outlined, label: 'Like', color: post.isLikedByUser ? colorScheme.primary : null, onTap: () {}),
              _actionButton(context, icon: Icons.comment_outlined, label: 'Comment', onTap: () {}),
              _actionButton(context, icon: Icons.share_outlined, label: 'Share', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: TextButton.styleFrom(foregroundColor: Theme.of(context).textTheme.bodyMedium?.color),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return DateFormat('MMM d').format(timestamp);
  }
}
