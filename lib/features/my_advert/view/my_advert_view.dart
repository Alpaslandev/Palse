import 'package:flutter/material.dart';

class MyAdvertView extends StatelessWidget {
  const MyAdvertView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanlarım'),
      ),
      body: const Center(child: Text('İlanlarım')),
    );
  }
}
