import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:idris_academy/models/submodule_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:provider/provider.dart';

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
  QuillController? _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _contentUrlController = TextEditingController();
  ContentType _selectedContentType = ContentType.text;

  bool _isLoading = true;
  bool _isSaving = false;
  SubmoduleModel? _existingSubmodule;

  @override
  void initState() {
    super.initState();
    _loadSubmoduleData();
  }

  Future<void> _loadSubmoduleData() async {
    if (widget.submoduleId != null) {
      final userService = Provider.of<UserService>(context, listen: false);
      _existingSubmodule = userService.getSubmodule(widget.courseId, widget.moduleId, widget.submoduleId!);
      if (_existingSubmodule != null) {
        // Pre-fill the title, although it's not editable for existing submodules on this screen.
        _titleController.text = _existingSubmodule!.title;
        _selectedContentType = _existingSubmodule!.contentType;
        _contentUrlController.text = _existingSubmodule!.contentUrl;
      }
    }
    if (_selectedContentType == ContentType.text) {
      _initializeController(_existingSubmodule);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _initializeController(SubmoduleModel? submodule) {
    final content = submodule?.transcript;
    Document doc;
    // Robustly handle legacy plain text and new Quill JSON format.
    if (content != null && content.trim().startsWith('[')) {
      try {
        // Attempt to parse as JSON (Quill format).
        doc = Document.fromJson(jsonDecode(content));
      } catch (e) {
        // If JSON parsing fails despite starting with '[', treat as plain text.
        debugPrint('Error decoding submodule content: $e');
        doc = Document()..insert(0, content);
      }
    } else {
      // If it's null, empty, or doesn't look like JSON, treat as plain text.
      doc = Document()..insert(0, content ?? '');
    }

    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _titleController.dispose();
    _contentUrlController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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
        title: Text(isEditing ? 'Edit: ${_existingSubmodule!.title}' : 'Add New Submodule'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveContent,
            tooltip: 'Save Submodule',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field (only for new submodules)
            if (!isEditing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Submodule Title',
                    hintText: 'e.g., The Structure of an Atom',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a title.' : null,
                ),
              ),
            // Content Type Selector
            DropdownButtonFormField<ContentType>(
              value: _selectedContentType,
              decoration: const InputDecoration(
                labelText: 'Content Type',
                border: OutlineInputBorder(),
              ),
              items: ContentType.values.map((type) {
                return DropdownMenuItem<ContentType>(
                  value: type,
                  child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                );
              }).toList(),
              onChanged: (ContentType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedContentType = newValue;
                    // Initialize or dispose the Quill controller based on selection
                    if (_selectedContentType == ContentType.text && _controller == null) {
                      _initializeController(null); // Initialize with a blank document
                    } else if (_selectedContentType != ContentType.text) {
                      _controller?.dispose();
                      _controller = null;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Conditionally show the Rich Text Editor or the URL field
            if (_selectedContentType == ContentType.text)
              _buildTextEditor()
            else
              _buildUrlEditor(),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlEditor() {
    return TextFormField(
      controller: _contentUrlController,
      decoration: const InputDecoration(
        labelText: 'Content URL',
        hintText: 'e.g., https://youtube.com/watch?v=...',
        border: OutlineInputBorder(),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Please enter a URL.' : null,
      keyboardType: TextInputType.url,
    );
  }

  Widget _buildTextEditor() {
    // Ensure controller is initialized before building the editor
    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Expanded(
      child: Column(
        children: [
          QuillSimpleToolbar(
            controller: _controller!,
            config: QuillSimpleToolbarConfig(
              embedButtons: FlutterQuillEmbeds.toolbarButtons(),
              showAlignmentButtons: true,
              multiRowsDisplay: false,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: QuillEditor(
              controller: _controller!,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: QuillEditorConfig(
                padding: const EdgeInsets.all(12),
                placeholder: 'Enter your content here...',
                embedBuilders: FlutterQuillEmbeds.editorBuilders(
                  imageEmbedConfig: QuillEditorImageEmbedConfig(
                    imageProviderBuilder: (context, imageUrl) {
                      if (imageUrl.startsWith('http')) {
                        return NetworkImage(imageUrl);
                      }
                      return FileImage(File(imageUrl));
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveContent() async {
    // For new submodules, ensure a title is provided.
    if (_existingSubmodule == null && _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title before saving.')),
      );
      return;
    }

    // Validate URL if content type requires it
    if (_selectedContentType != ContentType.text && _contentUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a URL for this content type.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final userService = Provider.of<UserService>(context, listen: false);

    // Prepare content based on the selected type
    final String transcript;
    final String contentUrl;

    if (_selectedContentType == ContentType.text) {
      transcript = jsonEncode(_controller!.document.toDelta().toJson());
      contentUrl = '';
    } else {
      transcript = ''; // No transcript for URL-based content
      contentUrl = _contentUrlController.text.trim();
    }

    try {
      if (_existingSubmodule != null) {
        // Update existing submodule's content
        final updatedSubmodule = _existingSubmodule!.copyWith(
          // Title is not editable on this screen, so we pass the existing one.
          title: _existingSubmodule!.title,
          transcript: transcript,
          contentType: _selectedContentType,
          contentUrl: contentUrl,
        );
        await userService.updateSubmodule(widget.courseId, widget.moduleId, updatedSubmodule);
      } else {
        // Add a new submodule
        final newSubmodule = SubmoduleModel(
          id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
          title: _titleController.text.trim(),
          transcript: transcript,
          contentType: _selectedContentType,
          contentUrl: contentUrl,
        );
        await userService.addSubmoduleToModule(
          widget.courseId,
          widget.moduleId,
          newSubmodule.title,
          newSubmodule.transcript,
          newSubmodule.contentType,
          newSubmodule.contentUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submodule saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving submodule: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}