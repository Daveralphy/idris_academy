import 'dart:io';

import 'package:flutter/material.dart';
import 'package:idris_academy/models/course_model.dart';
import 'package:idris_academy/models/user_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// A page for teachers to add a new course with its basic details.
class AddCoursePage extends StatefulWidget {
  const AddCoursePage({super.key});

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isSaving = false;
  List<UserModel> _teachers = [];
  String? _selectedTeacherId;
  File? _thumbnailImage;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    // Fetch the list of available teachers when the page loads.
    _loadTeachers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _loadTeachers() {
    final userService = Provider.of<UserService>(context, listen: false);
    setState(() {
      _teachers = userService.getTeachers();
    });
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return; // Prevent multiple calls while picker is active
    setState(() => _isPickingImage = true);

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (!mounted) return; // Check if the widget is still in the tree

    if (image != null) {
      setState(() {
        _thumbnailImage = File(image.path);
      });
    }

    setState(() => _isPickingImage = false);
  }

  void _saveCourse() async {
    // Validate the form before proceeding.
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      // Default placeholder, or save the selected image and get its local path.
      String thumbnailUrl = 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?q=80&w=2070&auto=format&fit=crop';
      if (_thumbnailImage != null) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final newImagePath = '${directory.path}/$fileName';
          await _thumbnailImage!.copy(newImagePath);
          thumbnailUrl = newImagePath;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving thumbnail: $e')),
            );
          }
          setState(() => _isSaving = false);
          return; // Stop if image saving fails
        }
      }

      // Find the selected teacher's name from the ID.
      final teacherName = _teachers.firstWhere((t) => t.id == _selectedTeacherId).name;

      // ignore: use_build_context_synchronously
      final userService = Provider.of<UserService>(context, listen: false);

      // Create a new CourseModel object.
      final newCourse = CourseModel(
        id: 'course_${DateTime.now().millisecondsSinceEpoch}', // Unique ID
        title: _titleController.text,
        description: _descriptionController.text,
        teacherName: teacherName,
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),
        // New courses start with an empty list of modules.
        modules: [],
        // Provide a placeholder thumbnail.
        thumbnailUrl: thumbnailUrl,
      );

      // Call the service to add the course.
      await userService.addCourse(newCourse);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Course'),
        actions: [
          IconButton(
            // Show a progress indicator while saving.
            icon: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                : const Icon(Icons.save_alt_outlined),
            onPressed: _isSaving ? null : _saveCourse,
            tooltip: 'Save Course',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Course Title',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Introduction to Flutter',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a course title.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Course Description',
                  border: OutlineInputBorder(),
                  hintText: 'A brief summary of what the course covers.',
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Flutter, Beginner, Mobile Dev',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter at least one tag.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTeacherId,
                decoration: const InputDecoration(
                  labelText: 'Course Teacher',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Select a teacher'),
                items: _teachers.map((UserModel teacher) {
                  return DropdownMenuItem<String>(
                    value: teacher.id,
                    child: Text(teacher.name),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTeacherId = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a teacher.' : null,
              ),
              const SizedBox(height: 24),
              Text('Course Thumbnail', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _thumbnailImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(_thumbnailImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: Theme.of(context).hintColor),
                            const SizedBox(height: 8),
                            const Text('Tap to select an image'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
