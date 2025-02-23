import 'package:flutter/material.dart';

// Yorum olmadığında gösterilecek boş durum widget'ı
class EmptyCommentView extends StatelessWidget {
  const EmptyCommentView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Henüz yorum yapılmamış',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
