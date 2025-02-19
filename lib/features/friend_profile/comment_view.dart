import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';

class CommentView extends StatelessWidget {
  final Customer customer;
  const CommentView({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yorumlar'),
      ),
      body: customer.comments?.isEmpty ?? true
          ? const Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: customer.comments?.length ?? 0,
              itemBuilder: (context, index) => _commentCard(customer.comments![index]),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _commentButton(context, 'Yorum Ekle', () {}),
        ),
      ),
    );
  }

  ElevatedButton _commentButton(BuildContext context, String title, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        _showCommentBottomSheet(context);
      },
      child: Text(title),
    );
  }

  void _showCommentBottomSheet(BuildContext context) {
    int selectedRating = 0;
    final commentController = TextEditingController();
    const int maxLength = 50;

    void _submitComment() async {
      if (selectedRating == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir puan seçin')),
        );
        return;
      }

      if (commentController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir yorum yazın')),
        );
        return;
      }

      try {
        final comment = Comment(
          comment: commentController.text,
          rating: selectedRating.toDouble(),
          commenterID: customer.userID, // Mevcut kullanıcı bilgileri
          commenterName: customer.fullName(),
          commenterProfilePictureUrl: customer.profilePictureUrl,
          commentDate: DateTime.now(),
        );

        await CustomerService().addComment(customer.userID!, comment);

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitComment,
                    child: const Text('Paylaş'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _commentCard(Comment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: comment.commenterProfilePictureUrl?.isNotEmpty == true ? NetworkImage(comment.commenterProfilePictureUrl!) : null,
                  child: comment.commenterProfilePictureUrl?.isEmpty ?? true ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.commenterName ?? 'İsimsiz Kullanıcı',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (comment.commentDate != null)
                        Text(
                          _formatDate(comment.commentDate!),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < (comment.rating ?? 0) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (comment.comment?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                comment.comment!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
