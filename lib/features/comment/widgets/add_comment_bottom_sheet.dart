import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart'; // Localization için import

// Yorum ekleme bottom sheet widget'ı
class AddCommentBottomSheet extends StatefulWidget {
  const AddCommentBottomSheet({
    super.key,
  });

  @override
  State<AddCommentBottomSheet> createState() => _AddCommentBottomSheetState();
}

class _AddCommentBottomSheetState extends State<AddCommentBottomSheet> {
  int selectedRating = 0;
  final commentController = TextEditingController();
  static const int maxLength = 50;

  void _submitComment() async {
    if (selectedRating == 0) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_select_rating'))),
      );
      return;
    }

    if (commentController.text.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_write_comment'))),
      );
      return;
    }
    final commentMap = {
      'comment': commentController.text,
      'rating': selectedRating,
    };

    Navigator.pop(context, commentMap);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr('profile_evaluation'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () {
                    setState(() {
                      selectedRating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              maxLength: maxLength,
              onChanged: (text) {
                if (text.length > maxLength) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('max_50_characters')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: context.tr('write_your_comment'),
                border: const OutlineInputBorder(),
                counterText: '${commentController.text.length}/$maxLength',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: _submitComment,
              child: Text(context.tr('share')),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
