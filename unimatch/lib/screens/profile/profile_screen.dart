import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/tm_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, user),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar — tappable to change photo
            GestureDetector(
              onTap: () => _pickAndUploadPhoto(context),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _resolveImage(user.photoUrl),
                    child: user.photoUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 14,
                      child: Icon(Icons.camera_alt, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
            Text(
              user.role.name.toUpperCase(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            if (user.bio != null && user.bio!.isNotEmpty)
              Text(user.bio!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (user.role == UserRole.tutor) ...[
              Text('Subjects: ${user.subjects.join(', ')}'),
              if (user.hourlyRate != null)
                Text('Hourly Rate: \$${user.hourlyRate}'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text(user.cvPdfUrl != null ? 'CV uploaded ✓' : 'Upload CV (PDF)'),
                subtitle: user.cvPdfUrl != null
                    ? Text(user.cvPdfUrl!.split('/').last,
                        style: const TextStyle(fontSize: 11))
                    : null,
                trailing: const Icon(Icons.upload_file),
                onTap: () => _pickAndUploadCv(context),
              ),
            ],
            const SizedBox(height: 32),
            TMButton(
              label: 'Sign Out',
              onPressed: () => context.read<AuthProvider>().signOut(),
              icon: Icons.logout,
            ),
          ],
        ),
      ),
    );
  }

  // Handles local file paths (from storage_service) and network URLs
  ImageProvider? _resolveImage(String? url) {
    if (url == null) return null;
    if (url.startsWith('/')) return FileImage(File(url));
    return NetworkImage(url);
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;

    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;

    await context.read<AuthProvider>().updateProfile(photoBytes: bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    }
  }

  Future<void> _pickAndUploadCv(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    if (!context.mounted) return;

    await context
        .read<AuthProvider>()
        .updateProfile(cvBytes: result.files.single.bytes!);

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('CV uploaded')));
    }
  }

  void _showEditDialog(BuildContext context, UserModel user) {
    final bioCtrl = TextEditingController(text: user.bio);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: bioCtrl,
          decoration: const InputDecoration(labelText: 'Bio'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<AuthProvider>()
                  .updateProfile(bio: bioCtrl.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}