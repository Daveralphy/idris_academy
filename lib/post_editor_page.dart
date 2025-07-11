import 'dart:io';
import 'package:flutter/material.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class PostEditorPage extends StatefulWidget {
  const PostEditorPage({super.key});

  @override
  State<PostEditorPage> createState() => _PostEditorPageState();
}

class _PostEditorPageState extends State<PostEditorPage> {
  final _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isPosting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _submitPost() async {
    if (_textController.text.trim().isEmpty && _imageFile == null) {
      return; // Don't post if there's no content
    }

    setState(() => _isPosting = true);

    // Connect to the UserService to actually save the post.
    final userService = Provider.of<UserService>(context, listen: false);
    await userService.addPost(_textController.text.trim(), image: _imageFile);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _textController.text.trim().isNotEmpty || _imageFile != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: (canPost && !_isPosting) ? _submitPost : null,
              child: _isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildUserInfo(context),
          const SizedBox(height: 16),
          _buildTextField(),
          const SizedBox(height: 16),
          if (_imageFile != null) _buildImagePreview(),
        ],
      ),
      bottomNavigationBar: _buildAttachmentBar(),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final user = Provider.of<UserService>(context, listen: false).currentUser;
    if (user == null) return const SizedBox.shrink();

    final imagePath = user.profilePicturePath;
    ImageProvider? backgroundImage;
    if (imagePath != null) {
      backgroundImage = imagePath.startsWith('http') ? NetworkImage(imagePath) : FileImage(File(imagePath)) as ImageProvider;
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: backgroundImage,
          child: backgroundImage == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Text(
          user.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _textController,
      decoration: const InputDecoration(
        hintText: 'What\'s on your mind?',
        border: InputBorder.none,
      ),
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) => setState(() {}), // Re-evaluate if the post button should be enabled
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.file(_imageFile!),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.6),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _removeImage,
              tooltip: 'Remove Image',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo_library_outlined), label: const Text('Photo')),
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video uploads coming soon!'))),
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Video'),
          ),
        ],
      ),
    );
  }
}
