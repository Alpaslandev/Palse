import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/features/comment/viewmodel/comment_view_model.dart';

// Yorum ekleme bottom sheet widget'ı
class AddCommentBottomSheet extends StatefulWidget {
  final CommentViewModel viewModel;
  final String currentUserID;
  final String currentUserName;
  final String? currentUserProfilePictureUrl;

  const AddCommentBottomSheet({
    super.key,
    required this.viewModel,
    required this.currentUserID,
    required this.currentUserName,
    this.currentUserProfilePictureUrl,
  });

  static void show(
    BuildContext context, {
    required CommentViewModel viewModel,
    required String currentUserID,
    required String currentUserName,
    String? currentUserProfilePictureUrl,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddCommentBottomSheet(
        viewModel: viewModel,
        currentUserID: currentUserID,
        currentUserName: currentUserName,
        currentUserProfilePictureUrl: currentUserProfilePictureUrl,
      ),
    );
  }

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

    try {
      final comment = Comment(
        comment: commentController.text,
        rating: selectedRating.toDouble(),
        commenterID: widget.currentUserID,
        commenterName: widget.currentUserName,
        commenterProfilePictureUrl: widget.currentUserProfilePictureUrl,
        commentDate: DateTime.now(),
      );

      await widget.viewModel.addComment(comment);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorumunuz başarıyla eklendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
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
    );
  }
}
