import 'dart:io';

import 'package:flutter/material.dart';
import 'package:idris_academy/models/course_model.dart';
import 'package:idris_academy/models/module_model.dart';
import 'package:idris_academy/models/submodule_model.dart';
import 'package:idris_academy/models/user_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:idris_academy/submodule_editor_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

/// A page for a teacher to edit a course and manage its modules.
class CourseEditorPage extends StatefulWidget {
  final String courseId;

  const CourseEditorPage({super.key, required this.courseId});

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  String? _selectedTeacherId;
  File? _thumbnailImage;
  List<UserModel> _teachers = [];
  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<UserService>(context, listen: false);
    // It's safe to assume the course exists as we navigated from a list of existing courses.
    final course = userService.getCourseFromCatalog(widget.courseId)!;

    _titleController = TextEditingController(text: course.title);
    _descriptionController = TextEditingController(text: course.description);
    _tagsController = TextEditingController(text: course.tags.join(', '));

    _teachers = userService.getTeachers();
    // Find the teacher ID that matches the current course's teacher name.
    try {
      _selectedTeacherId = _teachers.firstWhere((t) => t.name == course.teacherName).id;
    } catch (e) {
      // Handle case where teacher might not be in the list or name mismatch.
      _selectedTeacherId = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  /// A helper widget to display a course thumbnail from either a network URL or a local file path.
  Widget _buildCourseThumbnail(BuildContext context, {required String thumbnailUrl}) {
    final colorScheme = Theme.of(context).colorScheme;
    const double imageHeight = 200; // Larger height for editor page

    // Default error widget to show when an image fails to load.
    final errorWidget = Container(
      height: imageHeight,
      color: colorScheme.surface,
      child: Center(child: Icon(Icons.school_outlined, size: 48, color: colorScheme.onSurface.withOpacity(0.5))),
    );

    // Check if the URL is a network URL or a local file path.
    if (thumbnailUrl.startsWith('http')) {
      return Image.network(
        thumbnailUrl,
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: imageHeight,
            color: colorScheme.surface,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    } else {
      // It's a local file path.
      return Image.file(
        File(thumbnailUrl),
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    }
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

  Future<void> _saveCourseDetails(CourseModel originalCourse) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      String newThumbnailUrl = originalCourse.thumbnailUrl;
      if (_thumbnailImage != null) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final newImagePath = '${directory.path}/$fileName';
          await _thumbnailImage!.copy(newImagePath);
          newThumbnailUrl = newImagePath;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving new thumbnail: $e')),
            );
          }
          setState(() => _isSaving = false);
          return; // Stop if image saving fails
        }
      }

      final selectedTeacher = _teachers.firstWhere((t) => t.id == _selectedTeacherId);

      final updatedCourse = originalCourse.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        thumbnailUrl: newThumbnailUrl,
        teacherName: selectedTeacher.name,
        tags: _tagsController.text.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList(),
      );

      final userService = Provider.of<UserService>(context, listen: false);
      await userService.updateCourseDetails(updatedCourse);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course updated successfully!')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteCourse(CourseModel course) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Course?'),
        content: Text('Are you sure you want to permanently delete "${course.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await Provider.of<UserService>(context, listen: false).deleteCourse(course.id);
      if (mounted) {
        Navigator.pop(context); // Go back to the course list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${course.title}" was deleted.'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _deleteModule(CourseModel course, ModuleModel module) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Module?'),
        content: Text('Are you sure you want to permanently delete "${module.title}"? This will also delete all its submodules.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await Provider.of<UserService>(context, listen: false).deleteModule(course.id, module.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${module.title}" was deleted.'), backgroundColor: Colors.green));
    }
  }

  void _showEditModuleTitleDialog(BuildContext context, ModuleModel module) {
    final dialogFormKey = GlobalKey<FormState>();
    final dialogTitleController = TextEditingController(text: module.title);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Module Title'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: dialogTitleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Module Title'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a title.' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Provider.of<UserService>(context, listen: false).updateModuleTitle(widget.courseId, module.id, dialogTitleController.text);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddModuleDialog() {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Module'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Module Title',
                hintText: 'e.g., Introduction to Chemistry',
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a title.' : null,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Use Provider to call the service method without listening
                  Provider.of<UserService>(context, listen: false)
                      .addModuleToCourse(widget.courseId, titleController.text);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to get the latest course data from the service.
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final course = userService.getCourseFromCatalog(widget.courseId);

        // Handle case where course might not be found (e.g., deleted).
        if (course == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Course not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            // The title in the AppBar can now update if the user changes it and saves.
            title: Text('Edit: ${_titleController.text}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteCourse(course),
                tooltip: 'Delete Course',
              ),
              IconButton(
                icon: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                    : const Icon(Icons.save_alt_outlined),
                onPressed: _isSaving ? null : () => _saveCourseDetails(course),
                tooltip: 'Save Course Details',
              ),
            ],
          ),
          body: ListView(
            children: [
              // --- Editable Thumbnail ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _thumbnailImage != null
                            ? Image.file(_thumbnailImage!, fit: BoxFit.cover)
                            : _buildCourseThumbnail(context, thumbnailUrl: course.thumbnailUrl),
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined, color: Colors.white70, size: 40),
                              SizedBox(height: 8),
                              Text('Tap to change thumbnail', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // --- Editable Form Fields ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Course Title', border: OutlineInputBorder()),
                        style: Theme.of(context).textTheme.headlineSmall,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a title.' : null,
                        onChanged: (value) => setState(() {}), // To update AppBar title live
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Course Description', border: OutlineInputBorder(), alignLabelWithHint: true),
                        maxLines: 4,
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a description.' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedTeacherId,
                        decoration: const InputDecoration(labelText: 'Course Teacher', border: OutlineInputBorder()),
                        items: _teachers.map((UserModel teacher) => DropdownMenuItem<String>(value: teacher.id, child: Text(teacher.name))).toList(),
                        onChanged: (String? newValue) => setState(() => _selectedTeacherId = newValue),
                        validator: (value) => value == null ? 'Please select a teacher.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(labelText: 'Tags (comma-separated)', border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter at least one tag.' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Modules', style: Theme.of(context).textTheme.headlineSmall),
              ),
              if (course.modules.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Center(child: Text('No modules yet. Add one!')),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: course.modules.length,
                  itemBuilder: (context, index) {
                    final module = course.modules[index];
                    return ListTile(
                      key: ValueKey(module.id),
                      title: Text(module.title),
                      subtitle: Text('${module.submodules.length} submodules'),
                      onTap: () {
                        // Navigate to the page to manage the module's submodules
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ModuleEditorPage(courseId: course.id, moduleId: module.id)));
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteModule(course, module),
                            tooltip: 'Delete Module',
                            color: Theme.of(context).colorScheme.error,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEditModuleTitleDialog(context, module),
                            tooltip: 'Edit Module Title',
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ],
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;
                    // Explicitly type the list to avoid inference to List<dynamic>.
                    final List<ModuleModel> reorderedModules = List.from(course.modules);
                    final item = reorderedModules.removeAt(oldIndex);
                    reorderedModules.insert(newIndex, item);
                    userService.updateModuleOrder(widget.courseId, reorderedModules);
                  },
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _showAddModuleDialog();
            },
            tooltip: 'Add Module',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

/// A page for a teacher to edit a module and manage its submodules.
class ModuleEditorPage extends StatefulWidget {
  final String courseId;
  final String moduleId;

  const ModuleEditorPage({
    super.key,
    required this.courseId,
    required this.moduleId,
  });

  @override
  State<ModuleEditorPage> createState() => _ModuleEditorPageState();
}

class _ModuleEditorPageState extends State<ModuleEditorPage> {
  void _showEditSubmoduleTitleDialog(BuildContext context, SubmoduleModel submodule) {
    final dialogFormKey = GlobalKey<FormState>();
    final dialogTitleController = TextEditingController(text: submodule.title);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Submodule Title'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: dialogTitleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Submodule Title'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter a title.' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Provider.of<UserService>(context, listen: false).updateSubmoduleTitle(widget.courseId, widget.moduleId, submodule.id, dialogTitleController.text);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddSubmodule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmoduleEditorPage(
          courseId: widget.courseId,
          moduleId: widget.moduleId,
          // Pass null for submoduleId to indicate we are adding a new one
          submoduleId: null,
        ),
      ),
    );
  }

  Future<void> _deleteSubmodule(ModuleModel module, SubmoduleModel submodule) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Submodule?'),
        content: Text('Are you sure you want to permanently delete "${submodule.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await Provider.of<UserService>(context, listen: false).deleteSubmodule(widget.courseId, module.id, submodule.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${submodule.title}" was deleted.'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final module = userService.getModuleFromCourse(widget.courseId, widget.moduleId);

        if (module == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Module not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Edit: ${module.title}'),
          ),
          body: module.submodules.isEmpty
              ? const Center(child: Text('No submodules yet. Add one!'))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: module.submodules.length,
                  itemBuilder: (context, index) {
                    final submodule = module.submodules[index];
                    // Each item in a ReorderableListView needs a unique key.
                    return ListTile(
                      key: ValueKey(submodule.id),
                      leading: const Icon(Icons.article_outlined),
                      title: Text(submodule.title),
                      onTap: () {
                        // Navigate to the full editor to edit content
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmoduleEditorPage(courseId: widget.courseId, moduleId: widget.moduleId, submoduleId: submodule.id,),
                          ),
                        );
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteSubmodule(module, submodule),
                            tooltip: 'Delete Submodule',
                            color: Theme.of(context).colorScheme.error,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showEditSubmoduleTitleDialog(context, submodule),
                            tooltip: 'Edit Submodule Title',
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                        ],
                      ),
                    );
                  },
                  onReorder: (int oldIndex, int newIndex) {
                    // This logic handles the index change when an item is moved.
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    // Create a mutable copy of the list.
                    final List<SubmoduleModel> reorderedSubmodules =
                        List.from(module.submodules);
                    // Remove the item from its old position and insert it into the new one.
                    final SubmoduleModel item =
                        reorderedSubmodules.removeAt(oldIndex);
                    reorderedSubmodules.insert(newIndex, item);

                    // Call the service to persist the new order.
                    Provider.of<UserService>(context, listen: false)
                        .updateSubmoduleOrder(widget.courseId, widget.moduleId, reorderedSubmodules);
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _navigateToAddSubmodule();
            },
            tooltip: 'Add Submodule',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

