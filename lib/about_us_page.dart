import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBeliefSection(context),
            _buildVisionMissionSection(context),
            _buildStatsSection(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBeliefSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('ABOUT US', style: textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 8),
          Text('What we believe', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            'At Idris Academy, we believe that education should be simple, effective, and accessible to all. Our mission is to help students master complex academic concepts through well-structured video courses and interactive quizzes, making learning more engaging and results-driven.',
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Contact us'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisionMissionSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Text('Learn online', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold))),
          const SizedBox(height: 24),
          _buildFeatureTile(
            context,
            icon: Icons.visibility_outlined,
            title: 'Vision',
            subtitle: 'To inspire curiosity, foster understanding, and build confidence in every learner.',
          ),
          const SizedBox(height: 24),
          _buildFeatureTile(
            context,
            icon: Icons.flag_outlined,
            title: 'Mission',
            subtitle: 'To redefine how education is delivered, making it accessible and engaging for students around the globe.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatItem(context, '30', 'Happy\nStudents', icon: Icons.sentiment_satisfied_alt_outlined),
          const SizedBox(width: 48),
          _buildStatItem(context, '1', 'Professional\nTeacher', icon: Icons.person_outline),
          const SizedBox(width: 48),
          _buildStatItem(context, '5', 'Courses\n ', icon: Icons.school_outlined),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label, {required IconData icon}) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text(
          label,
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme.apply(bodyColor: colorScheme.onTertiary, displayColor: colorScheme.onTertiary);

    return Container(
      color: colorScheme.tertiary,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school, size: 40, color: colorScheme.onTertiary),
              const SizedBox(width: 12),
              Text('Idris Academy', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'We empower learners by transforming complex academic concepts into clear, engaging, and relatable lessons.',
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _socialIcon(Icons.language), // Website
              const SizedBox(width: 24),
              _socialIcon(Icons.play_circle_outline), // Placeholder for YouTube
              const SizedBox(width: 24),
              _socialIcon(Icons.music_note_outlined), // Placeholder for TikTok
              const SizedBox(width: 24),
              _socialIcon(Icons.facebook),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Icon(icon, color: Colors.white, size: 28);
  }
}