import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palseapp/features/profile_setup_steps/viewmodel/profile_setup_view_model.dart';
import 'dart:io';

import 'package:provider/provider.dart';

class ProfilePictureStep extends StatelessWidget {
  const ProfilePictureStep({super.key, required this.viewModel});
  final ProfileSetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            'Profil Fotoğrafınızı Ekleyin',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => _pickImage(context),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: viewModel.customer.profilePictureUrl != null ? FileImage(File(viewModel.customer.profilePictureUrl!)) : null,
              child: viewModel.customer.profilePictureUrl == null ? const Icon(Icons.camera_alt, size: 40) : null,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Fotoğrafınızı seçmek için dokunun',
            style: Theme.of(context).textTheme.bodyLarge,
          )
        ],
      ),
    );
  }

  void _pickImage(BuildContext context) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      context.read<ProfileSetupViewModel>().updateProfileImage(pickedFile.path);
    }
  }
}
