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
          return const MyHomePage();
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
      bottomNavigationBar: Container(
        decoration: appGradientDecoration,
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, // Make it transparent to show the container's gradient
          elevation: 0, // Remove the default shadow
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.space_dashboard_outlined),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_outlined),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inbox_outlined),
              label: 'Support',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
