import 'package:flutter/material.dart';
import 'package:palseapp/features/auth/profile_setup_steps/profile_picture_step.dart';

class UserInfoStep extends StatelessWidget {
  const UserInfoStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Info"),
      ),
      body: Column(
        children: [
          Text("Cinsiyetinizi seçiniz"),
          TextField(
            decoration: InputDecoration(
              labelText: "Ad",
            ),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: "Soyad",
            ),
          ),
          ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePictureStep()));
              },
              child: const Text("Profil Fotoğrafı Seç")),
        ],
      ),
    );
  }
}
