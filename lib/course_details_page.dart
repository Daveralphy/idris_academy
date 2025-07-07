import 'package:flutter/material.dart';
import 'package:idris_academy/models/course_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:idris_academy/course_content_page.dart';
import 'package:idris_academy/course_modules_page.dart';

class CourseDetailsPage extends StatelessWidget {
  final String courseId;

  const CourseDetailsPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    // We get the course from the general catalog, not the user's enrolled courses.
    final course = userService.getCourseFromCatalog(courseId);

    if (course == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Course not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(course.title),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildHeader(context, course),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(context, 'Course Objectives'),
                Text(course.description),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Module Breakdown'),
                ...course.modules.map((module) => Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: module.submodules
                            .map((submodule) => ListTile(
                                  leading: const Icon(Icons.play_circle_outline, size: 20),
                                  title: Text(submodule.title, style: Theme.of(context).textTheme.bodyMedium),
                                  dense: true,
                                ))
                            .toList(),
                      ),
                    )),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Instructor'),
                _buildInstructorInfo(context), // Placeholder
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Assessment'),
                const Text('This course includes graded quizzes and a final exam to test your knowledge.'),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Certificate'),
                const Text('Upon successful completion (80% or higher), you will receive a verifiable certificate from Idris Academy.'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildEnrollButton(context, course),
    );
  }

  Widget _buildHeader(BuildContext context, CourseModel course) {
    return Stack(
      children: [
        Image.network(
          course.thumbnailUrl,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 220,
            color: Theme.of(context).colorScheme.surface,
            // ignore: deprecated_member_use
            child: Icon(Icons.school_outlined, size: 60, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                // ignore: deprecated_member_use
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                course.tags.join(' • '),
                // ignore: deprecated_member_use
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInstructorInfo(BuildContext context) {
    // Placeholder for instructor info
    return const ListTile(
      leading: CircleAvatar(
        child: Icon(Icons.person),
      ),
      title: Text('Dr. Idris'),
      subtitle: Text('Lead Instructor, PhD in Chemistry'),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildEnrollButton(BuildContext context, CourseModel course) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final isEnrolled = userService.isEnrolled(course.id);

        final String buttonText;
        final VoidCallback onPressedAction;

        if (isEnrolled) {
          final userCourse = userService.getUserCourse(course.id);
          final hasStarted = userCourse?.lastAccessedSubmoduleId != null;

          if (hasStarted) {
            buttonText = 'Continue Learning';
            onPressedAction = () {
              // Jump directly to the last accessed lesson.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseContentPage(
                    courseId: course.id,
                    initialSubmoduleId: userCourse!.lastAccessedSubmoduleId,
                  ),
                ),
              );
            };
          } else {
            buttonText = 'Start Learning';
            onPressedAction = () {
              // Go to the modules page to start from the beginning.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseModulesPage(courseId: course.id),
                ),
              );
            };
          }
        } else {
          buttonText = 'Enroll Now';
          onPressedAction = () {
            // Just enroll, don't navigate. The Consumer will rebuild the UI.
            userService.enrollInCourse(course);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully enrolled in "${course.title}"!'),
                backgroundColor: Colors.green,
              ),
            );
          };
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: onPressedAction,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 18)),
          ),
        );
      },
    );
  }
}