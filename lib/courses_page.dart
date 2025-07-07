// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:idris_academy/models/course_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:idris_academy/course_details_page.dart';
import 'package:provider/provider.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = ['All', 'Science', 'Chemistry', 'Biology', 'Physics', 'Mathematics', 'Further Maths', 'Advanced'];

  void _filterCourses(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to rebuild the list when user data (like enrollments) changes.
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final allCourses = userService.getCourseCatalogWithUserData();
        final filteredCourses = allCourses.where((course) {
          final categoryMatch = _selectedCategory == 'All' || course.tags.any((tag) => tag.toLowerCase() == _selectedCategory.toLowerCase());
          final searchMatch = _searchQuery.isEmpty || course.title.toLowerCase().contains(_searchQuery.toLowerCase());
          return categoryMatch && searchMatch;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. Prominent Heading
            Text(
              'Explore Our Engaging Courses',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Courses',
                hintText: 'Enter course title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // 2. Course Categories/Filters
            _buildCategoryFilters(),
            const SizedBox(height: 24),

            // 3. Course Cards
            if (filteredCourses.isEmpty)
              const Center(
                child: Padding(padding: EdgeInsets.symmetric(vertical: 48.0), child: Text('No courses found matching your criteria.')),
              )
            else
              ...filteredCourses.map((course) => _buildCoursePreviewCard(context, course, userService)),

            // 4. "View All Courses" Button
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // In a real app, this might navigate to a page with ALL courses if this view is paginated.
                // For now, it can just reset the filter.
                _filterCourses('All');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
              ),
              child: const Text('View All Courses'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 40,
      // This horizontal ListView is scrollable if the categories exceed the screen width.
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return ChoiceChip(
            label: Text(category),
            selected: _selectedCategory == category,
            onSelected: (isSelected) {
              if (isSelected) {
                _filterCourses(category);
              }
            },
            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            labelStyle: TextStyle(
              color: _selectedCategory == category ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoursePreviewCard(BuildContext context, CourseModel course, UserService userService) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Always navigate to the details page for a consistent user experience.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CourseDetailsPage(courseId: course.id)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  course.thumbnailUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: colorScheme.surface,
                    child: Icon(Icons.image_not_supported, size: 50, color: colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ),
                // The play icon can be a visual cue but the whole card is tappable.
                Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.8), size: 60),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Text(course.tags.join(' • '), style: textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Title
                  Text(course.title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    course.description,
                    style: textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // The button is removed for a cleaner look, as the whole card is now tappable.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}