import 'package:flutter/material.dart';
import 'package:palseapp/features/profile_setup_steps/steps/user_info_step.dart';

class LocationStep extends StatelessWidget {
  const LocationStep({super.key, required this.nickname});
  final String nickname;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location"),
      ),
      body: Column(
        children: [
          Text("Merhaba, $nickname"),
          Text("Çevrendeki etkinlikleri keşfetmek için lütfen konumunuzu belirtiniz."),
          TextField(
            decoration: InputDecoration(
              labelText: "İl",
              //dropdown menü açılacak
            ),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: "İlçe",
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UserInfoStep()));
            },
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }
}
