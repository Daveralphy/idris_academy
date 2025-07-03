import 'dart:io';
import 'package:flutter/material.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:idris_academy/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // A single form key to manage validation for all editable fields
  final _formKey = GlobalKey<FormState>();

  // Flags to control the "edit mode" for each section
  bool _isEditingName = false;
  bool _isEditingPhoneNumber = false;
  bool _isEditingPassword = false;

  // Controllers for the text fields
  late TextEditingController _nameController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  String? _newPhoneNumber;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserService>(context, listen: false).currentUser;
    // Initialize controllers with the user's current data
    _nameController = TextEditingController(text: user?.name);
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final user = userService.currentUser;
        if (user == null) {
          return const Center(child: Text('User not found.'));
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Profile Picture
              _buildProfilePicture(context),
              const SizedBox(height: 24),

              // 2. User Details
              _buildDetailCard(
                context,
                title: 'Personal Information',
                children: [
                  _buildNameSection(user),
                  _buildInfoTile('Username', user.username),
                  _buildInfoTile('Date of Birth', user.dob != null ? DateFormat.yMMMMd().format(user.dob!) : 'Not set'),
                  _buildInfoTile('Email', user.email),
                  _buildPhoneNumberSection(user),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Security
              _buildDetailCard(
                context,
                title: 'Security',
                children: [_buildPasswordSection()],
              ),
              const SizedBox(height: 24),

              // 4. Payment Plan
              _buildDetailCard(
                context,
                title: 'Subscription',
                children: [
                  _buildInfoTile('Current Plan', userService.getPaymentPlan()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfilePicture(BuildContext context) {
    final user = Provider.of<UserService>(context).currentUser;
    final imagePath = user?.profilePicturePath;

    return Center(
      child: Stack(
        children: [
          // Outer circle acts as a border to make it stand out, especially in dark mode.
          CircleAvatar(
            radius: 72,
            // ignore: deprecated_member_use
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            child: CircleAvatar(
              radius: 70, // Increased from 60 to make it bigger
              backgroundColor: Theme.of(context).colorScheme.surface,
              backgroundImage: imagePath != null ? FileImage(File(imagePath)) : null,
              child: imagePath == null
                  ? Icon(Icons.person, size: 70, color: Theme.of(context).colorScheme.onSurface)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.black, size: 20),
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  /// A simple display tile for non-editable information.
  Widget _buildInfoTile(String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
  
  /// A display tile that includes an 'Edit' button.
  Widget _buildInfoTileWithEdit(String title, String subtitle, VoidCallback onEdit) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      trailing: IconButton(
        icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary),
        onPressed: onEdit,
      ),
    );
  }

  /// Builds the Full Name section, which can be in display or edit mode.
  Widget _buildNameSection(UserModel user) {
    if (_isEditingName) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (v) => v!.isEmpty ? 'Name cannot be empty' : null,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => setState(() => _isEditingName = false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final userService = Provider.of<UserService>(context, listen: false);
                      await userService.updateUserName(_nameController.text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated!')));
                      }
                      setState(() => _isEditingName = false);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            )
          ],
        ),
      );
    } else {
      return _buildInfoTileWithEdit('Full Name', user.name, () {
        setState(() {
          _nameController.text = user.name;
          _isEditingName = true;
        });
      });
    }
  }

  /// Builds the Phone Number section, which can be in display or edit mode.
  Widget _buildPhoneNumberSection(UserModel user) {
    if (_isEditingPhoneNumber) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntlPhoneField(
              decoration: const InputDecoration(
                labelText: 'New Phone Number',
                border: OutlineInputBorder(),
              ),
              initialCountryCode: 'NG',
              onChanged: (phone) {
                _newPhoneNumber = phone.completeNumber;
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => setState(() => _isEditingPhoneNumber = false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (_newPhoneNumber != null && _newPhoneNumber!.isNotEmpty) {
                      final userService = Provider.of<UserService>(context, listen: false);
                      await userService.updatePhoneNumber(_newPhoneNumber!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number updated!')));
                      }
                      setState(() => _isEditingPhoneNumber = false);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            )
          ],
        ),
      );
    } else {
      return _buildInfoTileWithEdit('Phone Number', user.phoneNumber ?? 'Not set', () async {
        final confirmed = await _showPasswordVerificationDialog();
        if (confirmed && mounted) {
          setState(() {
            _newPhoneNumber = user.phoneNumber;
            _isEditingPhoneNumber = true;
          });
        }
      });
    }
  }

  /// Builds the Password section, which can be in display or edit mode.
  Widget _buildPasswordSection() {
    if (_isEditingPassword) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
              validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              validator: (v) => v != _newPasswordController.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                    setState(() => _isEditingPassword = false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final userService = Provider.of<UserService>(context, listen: false);
                      await userService.updatePassword(_newPasswordController.text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated!')));
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                        setState(() => _isEditingPassword = false);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            )
          ],
        ),
      );
    } else {
      return _buildInfoTileWithEdit('Password', '********', () async {
        final confirmed = await _showPasswordVerificationDialog();
        if (confirmed && mounted) {
          setState(() {
            _isEditingPassword = true;
          });
        }
      });
    }
  }

  /// Shows a dialog to confirm the user's current password.
  Future<bool> _showPasswordVerificationDialog() async {
    final oldPasswordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Identity'),
        content: TextFormField(
          controller: oldPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Enter Your Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final userService = Provider.of<UserService>(context, listen: false);
              final isCorrect = await userService.verifyPassword(oldPasswordController.text);
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(isCorrect);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows a bottom sheet to choose between camera and gallery,
  /// handles permissions, and picks an image.
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Picture'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return; // User dismissed the sheet

    // Check and request permissions
    PermissionStatus status;
    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      status = await Permission.photos.request();
    }

    if (status.isPermanentlyDenied) {
      // The user has permanently denied the permission.
      // Open app settings to allow them to grant it.
      openAppSettings();
      return;
    }

    if (!status.isGranted) {
      // Permission is not granted.
      return;
    }

    // Pick image
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);

    if (pickedFile != null && mounted) {
      // Update service and UI
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.updateProfilePicture(pickedFile.path);
    }
  }
}