import 'package:flutter/material.dart';
import 'dart:io';
import 'package:idris_academy/certificates_page.dart';
import 'package:idris_academy/grades_page.dart';
import 'package:idris_academy/practice_exams_page.dart';
import 'package:idris_academy/models/course_model.dart';
import 'package:idris_academy/course_content_page.dart';
import 'package:idris_academy/course_details_page.dart';
import 'package:idris_academy/models/user_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:idris_academy/faqs_page.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) onNavigateToTab;

  const DashboardPage({super.key, required this.onNavigateToTab});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showImportantAnnouncement(context));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Use a Consumer to get the UserService and react to changes (like login/logout)
    return Consumer<UserService>(
      builder: (context, userService, child) {
        // If the user is not logged in, show a loading indicator or empty state.
        // This is a safeguard; the AuthWrapper should prevent this page from being built.
        if (!userService.isLoggedIn || userService.currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = userService.currentUser!;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildWelcomeSection(context, textTheme, user, widget.onNavigateToTab),
            const SizedBox(height: 24),

            _buildQuickAccessGrid(context, widget.onNavigateToTab),
            const SizedBox(height: 24),

            _buildInProgressCourses(context, textTheme, colorScheme, userService),
            const SizedBox(height: 24),

            _buildProgressSnapshot(context, userService),
            const SizedBox(height: 24),

            _buildSummaryRow(context, userService),
            const SizedBox(height: 24),

            _buildRecommendedCourses(context, colorScheme, userService),
            const SizedBox(height: 24),

            _buildSupportSection(context, colorScheme, widget.onNavigateToTab),
          ],
        );
      },
    );
  }

  void _showImportantAnnouncement(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    // Check the session-based flag in the service.
    if (userService.announcementShownThisSession) return;

    final announcement = userService.importantAnnouncement;

    if (announcement != null && announcement.isEnabled) {
      // Mark as shown for this session immediately to prevent re-triggering.
      userService.markAnnouncementAsShown();

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(announcement.title),
          content: Text(announcement.message),
          actions: [
            TextButton(
              child: const Text('Dismiss'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('View Details'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Navigate to notifications tab (index 2)
                widget.onNavigateToTab(2);
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWelcomeSection(BuildContext context, TextTheme textTheme, UserModel user, Function(int) onNavigateToTab) {
    final imagePath = user.profilePicturePath;

    return Row(
      children: [
        GestureDetector(
          onTap: () => widget.onNavigateToTab(4), // Navigate to Profile page (index 4)
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.surface,
            backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
            child: imagePath == null
                ? Icon(Icons.person, size: 30, color: Theme.of(context).colorScheme.onSurface)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back,", style: textTheme.titleMedium),
            Text(
              user.name, // Use the dynamic user name here!
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildInProgressCourses(BuildContext context, TextTheme textTheme, ColorScheme colorScheme, UserService userService) {
    final courses = userService.getInProgressCourses();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title: 'Continue Learning'),
        const SizedBox(height: 16),
        if (courses.isEmpty)
          _buildEmptyStateCard(
            context,
            'No courses in progress.',
            'Enroll in a course to get started!',
          )
        else
          SizedBox(
            height: 210, // Increased from 180 to 210
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return _buildCourseCard(
                  context,
                  course: course
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, {required CourseModel course}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(right: 14),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              course.thumbnailUrl,
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 80,
                  color: colorScheme.surface,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 80,
                color: colorScheme.surface,
                // ignore: deprecated_member_use
                child: Center(child: Icon(Icons.school_outlined, size: 32, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))),
            ),
            const SizedBox(height: 12), // Reduced spacing to prevent overflow
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          course.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Last: ${course.lastAccessed}',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        LinearProgressIndicator(
                          value: course.progress,
                          backgroundColor: Colors.black12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 2),
                        Text('${(course.progress * 100).toInt()}% Complete', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const Spacer(), // This pushes the button to the bottom
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourseContentPage(courseId: course.id)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          textStyle: Theme.of(context).textTheme.labelSmall,
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, Function(int) onNavigateToTab) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.0, // or even 1.8 for more height
      children: [
        _quickAccessCard(context, icon: Icons.add_circle_outline, label: 'Enroll in New Course', onTap: () => onNavigateToTab(1)),
        _quickAccessCard(context, icon: Icons.workspace_premium_outlined, label: 'My Certificates', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CertificatesPage()))),
        _quickAccessCard(context, icon: Icons.quiz_outlined, label: 'Practice Exams', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PracticeExamsPage()))),
        _quickAccessCard(context, icon: Icons.history_edu_outlined, label: 'My Grades', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GradesPage()))),
      ],
    );
  }

  Widget _quickAccessCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, UserService userService) {
    return Row(
      children: [Expanded(child: _summaryCard(context, icon: Icons.notifications_outlined, title: 'Notifications', count: userService.getNotificationCount(), onTap: () => widget.onNavigateToTab(2)))],
    );
  }

  Widget _summaryCard(BuildContext context, {required IconData icon, required String title, required int count, required VoidCallback onTap}) {
    return Card(
      clipBehavior: Clip.antiAlias, // Ensures the InkWell ripple is clipped to the card's shape
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Icon(icon),
                ],
              ),
              const SizedBox(height: 8),
              Text('$count Unread', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextButton(onPressed: onTap, child: const Text('View All')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSnapshot(BuildContext context, UserService userService) {
    final achievements = userService.getAchievements();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title: 'Your Achievements'),
        const SizedBox(height: 16),
        if (achievements.isEmpty)
          _buildEmptyStateCard(context, 'No achievements yet.', 'Complete courses to earn them!')
        else
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: achievements.entries.map((entry) {
                return _statItem(context, count: entry.value, label: entry.key);
              }).toList(),
            )
      ],
    );
  }

  Widget _statItem(BuildContext context, {required String count, required String label}) {
    return Column(
      children: [
        Text(count, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildRecommendedCourses(BuildContext context, ColorScheme colorScheme, UserService userService) {
    final courses = userService.getRecommendedCourses();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title: 'Recommended for You'),
        const SizedBox(height: 16),
        if (courses.isEmpty)
          _buildEmptyStateCard(context, 'No recommendations right now.', 'Browse our course catalog to find something new.')
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return _buildSmallCourseCard(context, course: course);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSmallCourseCard(BuildContext context, {required CourseModel course}) {
    return Card(
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailsPage(courseId: course.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0), // Match the card's shape
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(course.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 3, overflow: TextOverflow.ellipsis),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context, ColorScheme colorScheme, Function(int) onNavigateToTab) {
    return ListTile(
      leading: Icon(Icons.help_outline, color: colorScheme.primary),
      title: const Text('Need Help?'),
      subtitle: const Text('Visit our FAQ or contact support'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () async {
        // Navigate to the FAQs page and wait for a potential result.
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FaqsPage()),
        );
        // If the user tapped the "Chat" button on the FAQs page, switch to the support tab.
        if (result == 'go_to_support') {
          widget.onNavigateToTab(3); // Support is at index 3
        }
      },
    );
  }

  Widget _buildEmptyStateCard(BuildContext context, String title, String subtitle) {
    return Card(
      child: Container(
        height: 100,
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
