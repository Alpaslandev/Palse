import 'package:flutter/material.dart';

class FavoriteCategoryStep extends StatelessWidget {
  const FavoriteCategoryStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bu alanı daha sonra profilinizde düzenleyebilirsiniz."),
      ),
      body: Column(
        children: [
          Text("En sevdiğiniz kategoriyi seçiniz"),
        ],
      ),
    );
  }

  void _showCategorySelectionWarning(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "En az 3 kategori seçmelisiniz.",
            style: TextStyle(fontSize: 18.0),
          ),
        );
      },
    );
  }
}
