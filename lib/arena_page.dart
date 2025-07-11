import 'package:flutter/material.dart';
import 'package:idris_academy/models/post_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:idris_academy/widgets/post_card.dart';
import 'package:provider/provider.dart';

class ArenaPage extends StatelessWidget {
  const ArenaPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to get the latest posts from the service.
    return Scaffold(
      body: Consumer<UserService>(
        builder: (context, userService, child) {
          final List<PostModel> posts = userService.getArenaPosts();

          if (posts.isEmpty) {
            return const Center(child: Text('No posts in the Arena yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(post: post);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Placeholder for creating a new post
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Creating a new post is coming soon!')),
          );
        },
        tooltip: 'New Post',
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}
