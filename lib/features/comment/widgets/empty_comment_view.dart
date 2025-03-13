import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart'; // Localization için import

// Yorum olmadığında gösterilecek boş durum widget'ı
class EmptyCommentView extends StatelessWidget {
  const EmptyCommentView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.comment_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            context.tr('no_comments_yet'),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
