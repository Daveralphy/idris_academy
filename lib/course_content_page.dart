// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter/material.dart';
import 'package:idris_academy/models/course_model.dart';
import 'package:idris_academy/models/module_model.dart';
import 'package:idris_academy/models/submodule_model.dart';
import 'package:idris_academy/services/theme_service.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:idris_academy/quiz_page.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';

class CourseContentPage extends StatefulWidget {
  final String courseId;
  final String? initialSubmoduleId;

  const CourseContentPage({
    super.key,
    required this.courseId,
    this.initialSubmoduleId,
  });

  @override
  State<CourseContentPage> createState() => _CourseContentPageState();
}

class _CourseContentPageState extends State<CourseContentPage> with SingleTickerProviderStateMixin {
  SubmoduleModel? _currentSubmodule;
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoPlayerController;
  quill.QuillController? _quillController;
  final FocusNode _quillFocusNode = FocusNode();
  final ScrollController _quillScrollController = ScrollController();
  bool _videoCompleted = false;

  // Controllers for the new tabbed interface
  TabController? _tabController;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final userService = Provider.of<UserService>(context, listen: false);
    final course = userService.getUserCourse(widget.courseId);
    if (course != null && course.modules.isNotEmpty) {
      SubmoduleModel? startingSubmodule;

      // Try to find the specified initial submodule if provided.
      if (widget.initialSubmoduleId != null) {
        for (final module in course.modules) {
          try {
            startingSubmodule = module.submodules.firstWhere((s) => s.id == widget.initialSubmoduleId);
            break; // Found it, exit loop.
          } on StateError {
            // Not in this module, continue searching.
          }
        }
      }

      // If no initial submodule is found or provided, default to the first one in the course.
      if (startingSubmodule == null && course.modules.first.submodules.isNotEmpty) {
        startingSubmodule = course.modules.first.submodules.first;
      }

      if (startingSubmodule != null) {
        _selectSubmodule(startingSubmodule);
      }
    }
  }

  void _selectSubmodule(SubmoduleModel submodule) {
    // Update the user's last accessed submodule whenever a new one is selected.
    final userService = Provider.of<UserService>(context, listen: false);
    userService.updateLastAccessedSubmodule(widget.courseId, submodule.id);

    setState(() {
      _currentSubmodule = submodule;
      _videoCompleted = false;
      _youtubeController?.dispose();
      _youtubeController = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
      _quillController?.dispose();
      _quillController = null;

      switch (submodule.contentType) {
        case ContentType.youtubeVideo:
          if (submodule.contentUrl.isNotEmpty) {
            try {
              final videoId = YoutubePlayer.convertUrlToId(submodule.contentUrl);
              if (videoId != null) {
                _youtubeController = YoutubePlayerController(
                  initialVideoId: videoId,
                  flags: const YoutubePlayerFlags(autoPlay: false),
                )..addListener(() {
                    if (_youtubeController!.value.playerState == PlayerState.ended && !_videoCompleted) {
                      _onVideoCompleted();
                    }
                  });
              }
            } catch (e) {
              debugPrint("Error parsing YouTube URL: ${submodule.contentUrl}. Error: $e");
              // Controller will remain null, and the UI will show a placeholder.
            }
          }
          break;
        case ContentType.networkVideo:
          if (submodule.contentUrl.isNotEmpty) {
            try {
              final uri = Uri.parse(submodule.contentUrl);
              _videoPlayerController = VideoPlayerController.networkUrl(uri)
                ..initialize().then((_) {
                  if (mounted) setState(() {});
                })
                ..addListener(() {
                  if (_videoPlayerController!.value.position >= _videoPlayerController!.value.duration &&
                      !_videoCompleted &&
                      _videoPlayerController!.value.isInitialized) {
                    _onVideoCompleted();
                  }
                  if (mounted) setState(() {});
                });
            } catch (e) {
              debugPrint("Error parsing network video URL: ${submodule.contentUrl}. Error: $e");
              // Controller will remain null.
            }
          }
          break;
        case ContentType.image:
        case ContentType.text:
          // For text content, initialize the Quill controller.
          if (submodule.contentType == ContentType.text) {
            if (submodule.transcript.isNotEmpty) {
              try {
                final content = submodule.transcript;
                quill.Document doc;
                // Check if content is valid JSON (from Quill editor)
                if (content.trim().startsWith('[')) {
                  doc = quill.Document.fromJson(jsonDecode(content));
                } else {
                  // Handle legacy plain text.
                  doc = quill.Document()..insert(0, content);
                }
                _quillController = quill.QuillController(
                  document: doc,
                  selection: const TextSelection.collapsed(offset: 0),
                );
              } catch (e) {
                debugPrint("Error initializing Quill document: $e");
                // Create a fallback document showing the error or raw text.
                final doc = quill.Document()..insert(0, 'Error loading content.');
                _quillController = quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
              }
            }
          }
          break;
      }
    });
  }

  void _onVideoCompleted() {
    setState(() {
      _videoCompleted = true;
    });
    final userService = Provider.of<UserService>(context, listen: false);
    final course = userService.getUserCourse(widget.courseId);
    if (course != null && _currentSubmodule != null && !_currentSubmodule!.isCompleted) {
      userService.updateSubmoduleCompletion(course.id, _currentSubmodule!.id, true);
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _videoPlayerController?.dispose();
    _quillController?.dispose();
    _tabController?.dispose();
    _quillFocusNode.dispose();
    _quillScrollController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final course = userService.getUserCourse(widget.courseId);

        if (course == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Course not found or not enrolled.')),
          );
        }

        if (_currentSubmodule == null) {
          return Scaffold(
            appBar: AppBar(title: Text(course.title)),
            body: const Center(child: Text('This course has no content yet.')),
          );
        }

        final isText = _currentSubmodule!.contentType == ContentType.text;

        // Find the parent module of the current submodule for context.
        ModuleModel? parentModule;
        if (_currentSubmodule != null) {
          for (final module in course.modules) {
            if (module.submodules.any((s) => s.id == _currentSubmodule!.id)) {
              parentModule = module;
              break;
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            elevation: 0,
            actions: [
              Consumer<ThemeService>(
                builder: (context, themeService, child) {
                  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                  final toggleIcon = isDarkMode ? Icons.toggle_on : Icons.toggle_off;
                  final toggleColor = isDarkMode
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface;
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'theme') {
                        themeService.cycleTheme();
                      }
                    },
                    itemBuilder: (context) => [
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
                    ],
                    icon: const Icon(Icons.settings),
                  );
                },
              ),
            ],
          ),
          drawer: _buildCourseDrawer(context, course),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'Course Content',
                  ),
                ),
                // Display the parent module as a "breadcrumb" for context.
                if (parentModule != null) ...[
                  Text(
                    parentModule.title.toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 4),
                ],
                // Display the current submodule title prominently.
                Text(_currentSubmodule!.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                // The content player now handles all content types.
                _buildContentPlayer(),

                // Only show the tabs for video content, which has transcripts and notes.
                if (_currentSubmodule!.contentType == ContentType.youtubeVideo ||
                    _currentSubmodule!.contentType == ContentType.networkVideo) ...[
                  const Divider(height: 32.0, thickness: 1.0),
                  _buildTabbedContentSection(),
                  const SizedBox(height: 16),
                ],

                // For text lessons, show a dynamic completion/navigation button.
                // For other types, show standard navigation.
                if (isText) _buildTextLessonActions(context, course, _currentSubmodule!, parentModule, userService),
                if (!isText) _buildNavigationControls(context, course, _currentSubmodule!, parentModule, userService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseDrawer(BuildContext context, CourseModel course) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Color.lerp(Theme.of(context).colorScheme.primary, Colors.black, 0.2)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            // Use a Column to provide more context in the drawer header.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  course.title,
                  style: Theme.of(context).primaryTextTheme.headlineSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Course Modules',
                  style: Theme.of(context).primaryTextTheme.titleMedium?.copyWith(color: Colors.black.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          for (final module in course.modules)
            ExpansionTile(
              title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              initiallyExpanded: module.submodules.any((s) => s.id == _currentSubmodule?.id),
              children: module.submodules.map((submodule) {
                return ListTile(
                  leading: Icon(Icons.circle, size: 12, color: submodule.isCompleted ? Colors.green : Colors.grey.shade400),
                  title: Text(submodule.title),
                  selected: _currentSubmodule?.id == submodule.id,
                  selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  onTap: () {
                    _selectSubmodule(submodule);
                    Navigator.pop(context); // Close the drawer
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildContentPlayer() {
    if (_currentSubmodule == null) return const SizedBox.shrink();

    switch (_currentSubmodule!.contentType) {
      case ContentType.youtubeVideo:
        if (_youtubeController != null) {
          return YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
          );
        } else {
          return _buildContentPlaceholder('This YouTube video could not be loaded.', icon: Icons.videocam_off);
        }
        // ignore: dead_code
        break;
      case ContentType.networkVideo:
        if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
          return GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() {
                  _videoPlayerController!.value.isPlaying
                      ? _videoPlayerController!.pause()
                      : _videoPlayerController!.play();
                });
              }
            },
            child: AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_videoPlayerController!),
                  // Show a play/pause button overlay that is only visible when paused
                  if (!_videoPlayerController!.value.isPlaying)
                    Icon(
                      Icons.play_circle_filled,
                      color: Colors.white.withOpacity(0.7),
                      size: 60,
                    ),
                ],
              ),
            ),
          );
        } else {
          return _buildContentPlaceholder('This video could not be loaded.', icon: Icons.videocam_off);
        }
        // ignore: dead_code
        break;
      case ContentType.image:
        return Image.network(
          _currentSubmodule!.contentUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildContentPlaceholder('Image could not be loaded.', icon: Icons.image_not_supported),
        );
      case ContentType.text:
        // For text lessons, the main content is the rich text editor itself.
        if (_quillController != null) {
          // Reverting to IgnorePointer to ensure stability and prevent parameter errors.
          // This makes the content view-only and blocks all interactions.
          return IgnorePointer(
            child: SingleChildScrollView(
              child: quill.QuillEditor(
                controller: _quillController!,
                focusNode: _quillFocusNode,
                scrollController: _quillScrollController,
                config: quill.QuillEditorConfig(
                  // readOnly is removed to prevent the error. IgnorePointer handles non-interactivity.
                  padding: const EdgeInsets.all(12.0),
                  embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                  expands: false,
                  autoFocus: false,
                ),
              ),
            ),
          );
        } else {
          return _buildContentPlaceholder('Loading lesson...', icon: Icons.article_outlined);
        }
    }

    // Default/loading state
    // ignore: dead_code
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildContentPlaceholder(String message, {IconData? icon}) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextLessonActions(BuildContext context, CourseModel course, SubmoduleModel submodule, ModuleModel? parentModule, UserService userService) {
    if (submodule.contentType != ContentType.text) return const SizedBox.shrink();

    final prevSubmodule = userService.getPreviousSubmodule(course.id, submodule.id);

    VoidCallback? onNextPressed;
    Widget nextButtonChild;

    if (!submodule.isCompleted) {
      onNextPressed = () {
        userService.updateSubmoduleCompletion(course.id, submodule.id, true);
      };
      nextButtonChild = const Text('Mark as Complete');
    } else {
      final isLastInModule = parentModule?.submodules.last.id == submodule.id;
      final hasQuiz = parentModule?.quiz != null;

      if (isLastInModule && hasQuiz) {
        onNextPressed = () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => QuizPage(courseId: course.id, moduleId: parentModule!.id)),
          );
        };
        nextButtonChild = const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text('Go to Quiz'), SizedBox(width: 8), Icon(Icons.quiz_outlined, size: 18)],
        );
      } else {
        final nextSubmodule = userService.getNextSubmodule(course.id, submodule.id);
        if (nextSubmodule != null) {
          onNextPressed = () => _selectSubmodule(nextSubmodule);
          nextButtonChild = const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text('Next Lesson'), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18)],
          );
        } else {
          // This is the last lesson of the entire course.
          if (course.progress >= 1.0) {
            onNextPressed = null; // Disable the button
            nextButtonChild = const Text('Course Complete');
          } else {
            // Last lesson is done, but course not 100% complete. Show disabled "Next" button.
            onNextPressed = null;
            nextButtonChild = const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Next Lesson'), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18)],
            );
          }
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: prevSubmodule != null ? () => _selectSubmodule(prevSubmodule) : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Prev'),
        ),
        ElevatedButton(
          onPressed: onNextPressed,
          child: nextButtonChild,
        ),
      ],
    );
  }

  Widget _buildTranscriptSection() {
    // This section now only displays the plain text transcript for video lessons.
    // The rich text content is now handled by _buildContentPlayer.
    final transcript = _currentSubmodule?.transcript ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(transcript.isNotEmpty ? transcript : 'No transcript available for this lesson.'),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _notesController,
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            hintText: 'Type your personal notes for this lesson here...',
            border: InputBorder.none,
          ),
          textAlignVertical: TextAlignVertical.top,
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    // Placeholder for a future comments feature
    return const Center(child: Text('Comments feature coming soon.'));
  }

  Widget _buildTabbedContentSection() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Transcript'), Tab(text: 'My Notes'), Tab(text: 'Comments')],
        ),
        SizedBox(
          height: 300, // Adjust height as needed for the tab content area
          child: TabBarView(controller: _tabController, children: [
            _buildTranscriptSection(),
            _buildNotesSection(),
            _buildCommentsSection(),
          ]),
        )
      ],
    );
  }

  Widget _buildNavigationControls(BuildContext context, CourseModel course, SubmoduleModel submodule, ModuleModel? parentModule, UserService userService) {
    final prevSubmodule = userService.getPreviousSubmodule(course.id, submodule.id);

    VoidCallback? onNextPressed;
    Widget nextButtonChild;

    final isLastInModule = parentModule?.submodules.last.id == submodule.id;
    final hasQuiz = parentModule?.quiz != null;

    if (isLastInModule && hasQuiz) {
      // If it's the last submodule and there's a quiz, the next button goes to the quiz.
      onNextPressed = () {
        // Using pushReplacement to prevent user from going back to the last lesson from the quiz.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => QuizPage(courseId: course.id, moduleId: parentModule!.id)),
        );
      };
      nextButtonChild = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text('Go to Quiz'), SizedBox(width: 8), Icon(Icons.quiz_outlined, size: 18)],
      );
    } else {
      // Otherwise, it goes to the next lesson.
      final nextSubmodule = userService.getNextSubmodule(course.id, submodule.id);
      onNextPressed = nextSubmodule != null ? () => _selectSubmodule(nextSubmodule) : null;
      nextButtonChild = const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text('Next'), SizedBox(width: 8), Icon(Icons.arrow_forward)],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: prevSubmodule != null ? () => _selectSubmodule(prevSubmodule) : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Prev'),
        ),
        ElevatedButton(
          onPressed: onNextPressed,
          child: nextButtonChild,
        ),
      ],
    );
  }
}
