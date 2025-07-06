import 'package:flutter/material.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:idris_academy/teacher/manage_courses_page.dart';
import 'package:provider/provider.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: appGradientDecoration),
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
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: colorScheme.primary.withOpacity(0.15),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: NavigationBar(
          onDestinationSelected: _onItemTapped,
          selectedIndex: _selectedIndex,
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

