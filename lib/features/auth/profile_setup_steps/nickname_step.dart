import 'package:flutter/material.dart';
import 'package:palseapp/features/auth/profile_setup_steps/location_step.dart';

class NicknameStep extends StatelessWidget {
  NicknameStep({super.key});

  final TextEditingController _nicknameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nickname"),
      ),
      body: Column(
        children: [
          Text("Sana nasıl hitap edelim?"),
          TextField(
            controller: _nicknameController,
            decoration: InputDecoration(
              labelText: "Nickname",
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LocationStep(nickname: _nicknameController.text)));
            },
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }
}
