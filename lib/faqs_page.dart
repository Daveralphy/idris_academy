import 'package:flutter/material.dart';

class FaqsPage extends StatelessWidget {
  const FaqsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildFaqItem(
              context,
              question: 'What subjects do you offer?',
              answer:
                  'We offer a variety of subjects, including:\n\n• Mathematics (Algebra, Geometry, Trigonometry, and more)\n• Science (Chemistry, Physics, Biology)\n• English & Literature\n• History & Social Studies',
            ),
            _buildFaqItem(
              context,
              question: 'Can I study at my own pace?',
              answer:
                  'Yes, absolutely! All our courses are self-paced, so you can learn on your own schedule and revisit lessons as many times as you need.',
            ),
            _buildFaqItem(
              context,
              question: 'Are there quizzes and practice tests?',
              answer:
                  'Yes, each course includes interactive quizzes and practice tests to help you check your understanding and prepare for exams effectively.',
            ),
            _buildFaqItem(
              context,
              question: 'What is Idris Academy about?',
              answer:
                  'Idris Academy is an online learning platform that provides high-quality video courses with interactive quizzes to help students master academic subjects. Our goal is to simplify complex topics and prepare students for exams like UTME with confidence.',
            ),
            _buildFaqItem(
              context,
              question: 'How do your courses work?',
              answer:
                  'Our courses consist of pre-recorded video lessons that you can watch anytime. Each lesson is followed by quizzes to reinforce learning. You can track your progress and access all materials through your dashboard.',
            ),
            _buildFaqItem(
              context,
              question: 'Who are these courses for?',
              answer:
                  'Our courses are designed for secondary school students, as well as candidates preparing for major exams like UTME, WAEC, and NECO. We also have courses for anyone looking to refresh their knowledge on core academic subjects.',
            ),
            _buildFaqItem(
              context,
              question: 'Can I access the courses on my phone?',
              answer:
                  'Yes! Our courses are mobile-friendly, allowing you to learn on any device—laptop, tablet, or smartphone—anytime, anywhere.',
            ),
            _buildFaqItem(
              context,
              question: 'How do I enroll in a course?',
              answer:
                  'To enroll, simply navigate to the "Courses" page, select the course you are interested in, and follow the on-screen instructions to complete the enrollment process.',
            ),
            _buildFaqItem(
              context,
              question: 'Do you offer group or school packages?',
              answer:
                  'Yes, we do! We offer special packages for schools and study groups. Please contact our support team for more information on custom packages and pricing.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FAQ', style: textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 8),
        Text('Frequently Asked Questions', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          'Got questions? We’ve got answers! Find everything you need to know about our courses, enrollment, learning process, refunds, and more. If you don’t see your question here, chat with our support bot for instant answers!',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            // Pop this page and return a value to signal a navigation change.
            Navigator.of(context).pop('go_to_support');
          },
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Chat with our bot'),
        ),
      ],
    );
  }

  Widget _buildFaqItem(BuildContext context, {required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        childrenPadding: const EdgeInsets.all(16.0),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(answer),
        ],
      ),
    );
  }
}