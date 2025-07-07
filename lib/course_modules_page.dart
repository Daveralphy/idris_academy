import 'package:flutter/material.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:idris_academy/course_content_page.dart';

class CourseModulesPage extends StatelessWidget {
  final String courseId;

  const CourseModulesPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final course = userService.getUserCourse(courseId);

        if (course == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Course not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(course.title),
          ),
          body: ListView.builder(
            itemCount: course.modules.length,
            itemBuilder: (context, index) {
              final module = course.modules[index];
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: module.submodules.map((submodule) {
                    final isCompleted = submodule.isCompleted;
                    return ListTile(
                      leading: Icon(
                        isCompleted ? Icons.check_circle : Icons.play_circle_outline,
                        color: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(submodule.title),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseContentPage(
                              courseId: course.id,
                              initialSubmoduleId: submodule.id,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
