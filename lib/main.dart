import 'package:flutter/material.dart';
import 'package:idris_academy/app_themes.dart';
import 'package:idris_academy/no_internet_page.dart';
import 'package:idris_academy/dashboard_page.dart';
import 'package:idris_academy/faqs_page.dart';
import 'package:idris_academy/about_us_page.dart';
import 'package:idris_academy/login_page.dart';
import 'package:idris_academy/courses_page.dart';
import 'package:idris_academy/notifications_page.dart';
import 'package:idris_academy/support_page.dart';
import 'package:idris_academy/profile_page.dart';
import 'package:idris_academy/services/connectivity_service.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:idris_academy/models/submodule_model.dart';
import 'package:idris_academy/models/module_model.dart';
import 'package:idris_academy/models/course_model.dart';
import 'package:idris_academy/models/user_model.dart';
import 'package:idris_academy/services/theme_service.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, ConnectivityService>(
      builder: (context, themeService, connectivityService, child) {
        return MaterialApp(
          title: 'Idris Academy',
          theme: AppThemes.getLightTheme(themeService.fontScale),
          darkTheme: AppThemes.getDarkTheme(themeService.fontScale),
          themeMode: themeService.themeMode,
          home: Builder(
            builder: (context) {
              if (connectivityService.isConnected) {
                return const AuthWrapper();
              } else {
                return const NoInternetPage();
              }
            },
          ),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        if (userService.isLoggedIn) {
          // Role-based routing: Direct users to the correct home page.
          if (userService.isTeacher) {
            return const TeacherHomePage();
          }
          return const MyHomePage(); // Default to the student home page.
        }
        return const LoginPage();
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // Changed to a late final instance variable to allow passing instance methods.
  late final List<Widget> _pageOptions;

  @override
  void initState() {
    super.initState();
    _pageOptions = <Widget>[
      DashboardPage(onNavigateToTab: _onItemTapped),
      const CoursesPage(),
      const NotificationsPage(),
      const SupportPage(),
      const ProfilePage(),
    ];
  }

  static const List<String> _pageTitles = <String>[
    'Idris Academy', // Special case for Dashboard
    'Courses',
    'Notifications',
    'Support',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDashboard = _selectedIndex == 0;
    final colorScheme = Theme.of(context).colorScheme;

    // Define a consistent gradient decoration to be used across the app.
    final appGradientDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [
          colorScheme.primary,
          // A slightly darker shade of the primary color for a subtle effect
          Color.lerp(colorScheme.primary, Colors.black, 0.2)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );

    return Scaffold(
      // The drawer scrim color now correctly defaults to the theme's scrimColor.
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make AppBar transparent to show the gradient
        elevation: 0, // Remove shadow for a seamless look
        flexibleSpace: Container(decoration: appGradientDecoration),
        title: isDashboard
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school),
                  SizedBox(width: 8.0),
                  Text("Idris Academy"),
                ],
              )
            : Text(_pageTitles[_selectedIndex]),
        centerTitle: isDashboard,
        actions: [
          Consumer<ThemeService>(
            builder: (context, themeService, child) {
              // Determine the current visual state of the app.
              final isDarkMode = Theme.of(context).brightness == Brightness.dark;

              // Choose the icon and color based on the current theme.
              final IconData toggleIcon = isDarkMode ? Icons.toggle_on : Icons.toggle_off;
              final Color toggleColor = isDarkMode
                  ? Theme.of(context).colorScheme.primary // Orange for dark mode
                  : Theme.of(context).colorScheme.onSurface; // Dark for light mode

              return PopupMenuButton<String>(
                onSelected: (String value) {
                  if (value == 'theme') {
                    themeService.cycleTheme();
                  } else if (value == 'font') {
                    themeService.cycleFontSize();
                  } else if (value == 'notifications') {
                    themeService.toggleNotifications();
                  }
                  // Handle other settings later
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'theme',
                    child: Row(
                      children: [
                        const Text('Theme'),
                        const Spacer(),
                        Icon(toggleIcon, color: toggleColor, size: 30),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'notifications',
                    child: Row(
                      children: [
                        const Text('Notifications'),
                        const Spacer(),
                        Icon(
                          themeService.notificationsEnabled ? Icons.toggle_on : Icons.toggle_off,
                          color: themeService.notificationsEnabled
                              ? Theme.of(context).colorScheme.primary
                              // ignore: deprecated_member_use
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(Icons.settings),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 40.0, right: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close Menu',
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Courses'),
              onTap: () {
                // Close the drawer
                Navigator.pop(context);
                // Switch to the Courses page (index 1)
                _onItemTapped(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_work_outlined),
              title: const Text('Affiliates'),
              onTap: () {
                // First, close the drawer.
                Navigator.pop(context);
                // Then, show the dialog.
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Continue to Website'),
                      content: const Text('You will be taken to our website to continue with the affiliate program. Do you wish to proceed?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Go Back'),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                        TextButton(
                          child: const Text('Agree'),
                          onPressed: () async {
                            final Uri url = Uri.parse('https://idrisacademy.com/join-affiliates/');
                            Navigator.of(dialogContext).pop(); // Close the dialog
                            if (!await launchUrl(url)) {
                              // Could not launch the URL, show an error message
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not launch $url')),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: const Text('FAQs'),
              onTap: () async {
                Navigator.pop(context); // Close the drawer
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FaqsPage()),
                );
                // If the user tapped the "Chat" button on the FAQs page, switch to the support tab.
                if (result == 'go_to_support') {
                  _onItemTapped(3); // Support is at index 3
                }
              },
            ),
            Consumer<UserService>(
              builder: (context, userService, child) {
                if (userService.isTeacher) {
                  return ListTile(
                    leading: Icon(Icons.edit_note, color: colorScheme.primary),
                    title: const Text('Manage Courses'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TeacherHomePage()),
                      );
                    },
                  );
                }
                return const SizedBox.shrink(); // Return empty widget if not a teacher
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                // Close the drawer first
                Navigator.pop(context);
                // Then log out
                Provider.of<UserService>(context, listen: false).logout();
              },
            ),
          ],
        ),
      ),
      body: _pageOptions.elementAt(_selectedIndex),
      // Switched to NavigationBar for Material 3 styling and indicator support.
      bottomNavigationBar: Container(
        decoration: appGradientDecoration,
        child: NavigationBar(
          onDestinationSelected: _onItemTapped,
          selectedIndex: _selectedIndex,
          backgroundColor: Colors.transparent,
          // This creates the "curved edge square" effect on the selected item.
          // ignore: deprecated_member_use
          indicatorColor: colorScheme.onPrimary.withOpacity(0.2),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          height: 70,
          // ignore: deprecated_member_use
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            // Use a more opaque color for unselected labels to improve visibility.
            // ignore: deprecated_member_use
            final color = states.contains(MaterialState.selected)
                ? colorScheme.onPrimary
                // ignore: deprecated_member_use
                : colorScheme.onPrimary.withOpacity(0.9);
            return TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500);
          }),
          destinations: <Widget>[
            NavigationDestination(
              // Increased opacity for better visibility on the gradient background.
              // ignore: deprecated_member_use
              icon: Icon(Icons.space_dashboard_outlined, color: colorScheme.onPrimary.withOpacity(0.9)),
              selectedIcon: Icon(Icons.space_dashboard, color: colorScheme.onPrimary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              // ignore: deprecated_member_use
              icon: Icon(Icons.school_outlined, color: colorScheme.onPrimary.withOpacity(0.9)),
              selectedIcon: Icon(Icons.school, color: colorScheme.onPrimary),
              label: 'Courses',
            ),
            NavigationDestination(
              // ignore: deprecated_member_use
              icon: Icon(Icons.notifications_none_outlined, color: colorScheme.onPrimary.withOpacity(0.9)),
              selectedIcon: Icon(Icons.notifications, color: colorScheme.onPrimary),
              label: 'Notifications',
            ),
            NavigationDestination(
              // ignore: deprecated_member_use
              icon: Icon(Icons.inbox_outlined, color: colorScheme.onPrimary.withOpacity(0.9)),
              selectedIcon: Icon(Icons.inbox, color: colorScheme.onPrimary),
              label: 'Support',
            ),
            NavigationDestination(
              // ignore: deprecated_member_use
              icon: Icon(Icons.person_outline, color: colorScheme.onPrimary.withOpacity(0.9)),
              selectedIcon: Icon(Icons.person, color: colorScheme.onPrimary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- TEACHER SECTION -------------------
// NOTE: It's recommended to move the following widgets into their own separate files
// for better project organization (e.g., teacher_home_page.dart, manage_courses_page.dart).

/// The main page for logged-in teachers, providing access to teacher-specific tools.
class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _teacherPages = <Widget>[
    const TeacherDashboardPage(),
    const ManageCoursesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Logout the user and return to the login page
              Provider.of<UserService>(context, listen: false).logout();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _teacherPages,
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        // This creates the "curved edge square" effect on the selected item.
        // ignore: deprecated_member_use
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            label: 'Courses',
          ),
        ],
      ),
    );
  }
}

/// A placeholder dashboard page for teachers.
class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80),
            SizedBox(height: 16),
            Text(
              'Welcome, Teacher!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Use the navigation below to manage your courses.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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

  void _showAddSubmoduleDialog() {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add New Submodule'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Submodule Title',
                hintText: 'e.g., The Structure of an Atom',
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
                  Provider.of<UserService>(context, listen: false).addSubmoduleToModule(
                      widget.courseId, widget.moduleId, titleController.text, '', ContentType.text, '');
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
                            builder: (_) => SubmoduleEditorPage(courseId: widget.courseId, moduleId: widget.moduleId, submoduleId: submodule.id),
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
              _showAddSubmoduleDialog();
            },
            tooltip: 'Add Submodule',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

/// A page for a teacher to add or edit a submodule.
class SubmoduleEditorPage extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final String? submoduleId; // Null when adding a new submodule

  const SubmoduleEditorPage({
    super.key,
    required this.courseId,
    required this.moduleId,
    this.submoduleId,
  });

  @override
  State<SubmoduleEditorPage> createState() => _SubmoduleEditorPageState();
}

class _SubmoduleEditorPageState extends State<SubmoduleEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _transcriptController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;
  SubmoduleModel? _existingSubmodule;

  @override
  void initState() {
    super.initState();
    if (widget.submoduleId != null) {
      // Editing an existing submodule
      _loadExistingSubmodule();
    } else {
      // Adding a new submodule
      setState(() => _isLoading = false);
    }
  }

  /// Converts a Quill Delta JSON string to plain text for backward compatibility.
  String _plainTextFromDelta(String jsonString) {
    // If it's not a JSON array, assume it's already plain text.
    if (jsonString.isEmpty || !jsonString.startsWith('[')) {
      return jsonString;
    }
    try {
      final List<dynamic> delta = jsonDecode(jsonString);
      final buffer = StringBuffer();
      for (var op in delta) {
        if (op is Map<String, dynamic> && op.containsKey('insert')) {
          final insertData = op['insert'];
          if (insertData is String) {
            buffer.write(insertData);
          }
        }
      }
      return buffer.toString();
    } catch (e) {
      // If decoding fails for any reason, return the original string.
      return jsonString;
    }
  }

  void _loadExistingSubmodule() {
    final userService = Provider.of<UserService>(context, listen: false);
    _existingSubmodule =
        userService.getSubmodule(widget.courseId, widget.moduleId, widget.submoduleId!);
    if (_existingSubmodule != null) {
      _titleController.text = _existingSubmodule!.title;
      final transcript = _existingSubmodule!.transcript;
      // Convert potential Quill Delta to plain text for editing.
      _transcriptController.text = _plainTextFromDelta(transcript);
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  void _saveSubmodule() async {
    final isEditing = _existingSubmodule != null;
    // Only validate the form if we are adding a new submodule (which has a title field).
    if (isEditing || _formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final userService = Provider.of<UserService>(context, listen: false);
      // Get the plain text content from the new controller.
      final transcriptContent = _transcriptController.text;

      if (_existingSubmodule != null) {
        // Update existing submodule
        final updatedSubmodule = _existingSubmodule!.copyWith(
          transcript: transcriptContent,
          title: _existingSubmodule!.title, // Pass the existing title as it's required
        );
        await userService.updateSubmodule(
            widget.courseId, widget.moduleId, updatedSubmodule);
      } else {
        // Creating a new submodule
        // The service now handles creating the SubmoduleModel and numbering it.
        await userService.addSubmoduleToModule(widget.courseId, widget.moduleId,
            _titleController.text, // Just the topic title
            transcriptContent, // The content
            ContentType.text, // Default content type
            '' // Default content URL
            );
      }

      if (mounted) { // Check if the widget is still in the tree
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingSubmodule != null;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'Edit Submodule' : 'Add Submodule')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Submodule' : 'Add Submodule'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                : const Icon(Icons.save_alt_outlined),
            onPressed: _isSaving ? null : _saveSubmodule,
            tooltip: 'Save Submodule',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isEditing) ...[
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Submodule Title',
                      hintText: 'e.g., The Structure of an Atom',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a title.' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                // The content field is always visible
                Expanded(
                  child: TextFormField(
                    controller: _transcriptController,
                    decoration: const InputDecoration(
                      labelText: 'Content / Transcript',
                      hintText: 'Enter the submodule content here.',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true, // Good for multiline fields
                    ),
                    maxLines: null, // Allows for an unlimited number of lines
                    expands: true, // Makes the field expand to fill the space
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  File? _thumbnailImage;
  List<UserModel> _teachers = [];
  String? _selectedTeacherId;
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
