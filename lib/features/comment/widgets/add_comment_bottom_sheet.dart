import 'package:flutter/material.dart';

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
        const SnackBar(content: Text('Lütfen bir puan seçin')),
      );
      return;
    }

    if (commentController.text.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir yorum yazın')),
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
            const Text(
              'Profil Değerlendirmesi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    const SnackBar(
                      content: Text('En fazla 50 karakter girebilirsiniz!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Yorumunuzu yazın...',
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
              child: const Text('Paylaş'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
