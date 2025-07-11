import 'package:flutter/material.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:idris_academy/course_content_page.dart';
import 'package:idris_academy/quiz_page.dart';

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
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${(course.progress * 100).toInt()}% Complete',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0),
                  itemCount: course.modules.length,
                  itemBuilder: (context, index) {
                    final module = course.modules[index];
                    return Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ExpansionTile(
                          title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          children: [
                            ...module.submodules.map((submodule) {
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
                            }),
                            if (module.quiz != null)
                              ListTile(
                                leading: Icon(Icons.quiz_outlined, color: Theme.of(context).colorScheme.primary),
                                title: Text(module.quiz!.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuizPage(
                                        courseId: course.id,
                                        moduleId: module.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
