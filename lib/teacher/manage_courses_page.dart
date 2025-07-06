import 'package:flutter/material.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:idris_academy/teacher/add_course_page.dart';
import 'package:idris_academy/teacher/course_editor_page.dart';
import 'package:provider/provider.dart';

/// Page for teachers to manage their courses, modules, and submodules.
class ManageCoursesPage extends StatefulWidget {
  const ManageCoursesPage({super.key});

  @override
  State<ManageCoursesPage> createState() => _ManageCoursesPageState();
}

class _ManageCoursesPageState extends State<ManageCoursesPage> {
  void _addCourse() async {
    // Navigate to the AddCoursePage. The Consumer will handle UI updates
    // automatically when a new course is added to the UserService.
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const AddCoursePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a Consumer to listen for changes in the course catalog.
      body: Consumer<UserService>(
        builder: (context, userService, child) {
          final courses = userService.getCourseCatalog();
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return ListTile(
                leading: const Icon(Icons.book_outlined),
                title: Text(course.title),
                subtitle: Text('${course.modules.length} modules'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to the editor page for the selected course.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CourseEditorPage(courseId: course.id)),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCourse,
        tooltip: 'Add Course',
        child: const Icon(Icons.add),
      ),
    );
  }
}

