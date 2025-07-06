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
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';

class CourseContentPage extends StatefulWidget {
  final String courseId;

  const CourseContentPage({
    super.key,
    required this.courseId,
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
    if (course != null && course.modules.isNotEmpty && course.modules.first.submodules.isNotEmpty) {
      _selectSubmodule(course.modules.first.submodules.first);
    }
  }

  void _selectSubmodule(SubmoduleModel submodule) {
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
                const SizedBox(height: 8),
                LinearProgressIndicator(value: course.progress, minHeight: 6, backgroundColor: Colors.grey.shade300),
                Text('${(course.progress * 100).toInt()}% Complete', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 24),
                // The content player now handles all content types.
                _buildContentPlayer(),
                const Divider(height: 32.0, thickness: 1.0),
                // The new tabbed interface for transcript, notes, and comments.
                _buildTabbedContentSection(),
                const SizedBox(height: 16),
                // For text lessons, show a dynamic completion/navigation button.
                // For other types, show standard navigation.
                if (isText) _buildTextLessonActions(context, course, _currentSubmodule!, userService),
                if (!isText) _buildNavigationControls(context, course, _currentSubmodule!, userService),
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
        // For text lessons, show a placeholder in the player area.
        // The actual content is in the "Transcript" tab.
        return _buildContentPlaceholder('This is a reading lesson.\nSee the tabs below for content.',
            icon: Icons.article_outlined);
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

  Widget _buildTextLessonActions(BuildContext context, CourseModel course, SubmoduleModel submodule, UserService userService) {
    if (submodule.contentType != ContentType.text) return const SizedBox.shrink();

    final prevSubmodule = userService.getPreviousSubmodule(course.id, submodule.id);
    final nextSubmodule = userService.getNextSubmodule(course.id, submodule.id);

    VoidCallback? onNextPressed;
    Widget nextButtonChild;

    if (!submodule.isCompleted) {
      onNextPressed = () {
        userService.updateSubmoduleCompletion(course.id, submodule.id, true);
      };
      nextButtonChild = const Text('Mark as Complete');
    } else {
      if (nextSubmodule != null) {
        onNextPressed = () => _selectSubmodule(nextSubmodule);
        nextButtonChild = const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Next Lesson'),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18),
          ],
        );
      } else {
        // This is the last lesson. Only show "Course Complete" if progress is 100%.
        if (course.progress >= 1.0) {
          onNextPressed = null; // Disable the button
          nextButtonChild = const Text('Course Complete');
        } else {
          // Last lesson is done, but course not 100% complete. Show disabled "Next" button.
          onNextPressed = null;
          nextButtonChild = const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Next Lesson'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          );
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
    // For text lessons, display the rich text editor.
    if (_currentSubmodule?.contentType == ContentType.text && _quillController != null) {
      // To definitively solve the parameter issues, we wrap the editor in an
      // IgnorePointer. This blocks all user interaction, effectively making
      // the editor a read-only viewer without relying on a problematic parameter.
      return IgnorePointer(
        child: SingleChildScrollView(
          child: quill.QuillEditor(
            controller: _quillController!,
            focusNode: _quillFocusNode,
            scrollController: _quillScrollController,
            // We use the standard config from the working editor page.
            // The IgnorePointer widget handles the "read-only" state.
            config: quill.QuillEditorConfig(
              padding: const EdgeInsets.all(12.0),
              embedBuilders: FlutterQuillEmbeds.editorBuilders(),
              expands: false,
              autoFocus: false,
            ),
          ),
        ),
      );
    }

    // For other content types, display the plain text transcript.
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

  Widget _buildNavigationControls(BuildContext context, CourseModel course, SubmoduleModel submodule, UserService userService) {
    final prevSubmodule = userService.getPreviousSubmodule(course.id, submodule.id);
    final nextSubmodule = userService.getNextSubmodule(course.id, submodule.id);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: prevSubmodule != null ? () => _selectSubmodule(prevSubmodule) : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Prev'),
        ),
        ElevatedButton(
          onPressed: nextSubmodule != null ? () => _selectSubmodule(nextSubmodule) : null,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Next'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ],
    );
  }
}
