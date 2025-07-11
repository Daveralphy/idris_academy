import 'package:flutter/material.dart';

class ArenaPage extends StatelessWidget {
  const ArenaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar will be provided by MyHomePage, so we don't need one here.
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Welcome to the Arena!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Posts and comments from other students will appear here. Start a discussion!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
