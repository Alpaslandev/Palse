import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palseapp/features/auth/profile_setup_steps/favorite_category_step.dart';

class ProfilePictureStep extends StatelessWidget {
  const ProfilePictureStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Picture"),
      ),
      body: Column(
        children: [
          Text("Neredeyse bitti! Şimdi profil fotoğrafınızı seçiniz."),
          ElevatedButton(onPressed: _pickImage, child: const Text("Profil Fotoğrafı Seç")),
          ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoriteCategoryStep()));
              },
              child: const Text("Devam Et")),
        ],
      ),
    );
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      debugPrint(pickedFile.path);
    }
  }
}
