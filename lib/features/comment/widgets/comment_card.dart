import 'package:flutter/material.dart';
import 'package:palseapp/core/models/comment_model.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';

// Yorum kartı widget'ı
class CommentCard extends StatelessWidget {
  final Comment comment;
  final String currentUserId;
  final String profileOwnerId;
  final VoidCallback onDeleteTap;
  final VoidCallback onReportTap;

  const CommentCard({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.profileOwnerId,
    required this.onDeleteTap,
    required this.onReportTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleProfilePicture(imageUrl: comment.commenterProfilePictureUrl),
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      debugPrint('Yorum silme işlemi');
                      onDeleteTap();
                    } else if (value == 'report') {
                      debugPrint('Yorum şikayet etme işlemi');
                      onReportTap();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    // Yorumu yapan kişi veya yorumun yapıldığı profil sahibi ise silme butonu gösterilir
                    if (comment.commenterID == currentUserId || profileOwnerId == currentUserId)
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Yorumu Sil'),
                          ],
                        ),
                      ),
                    PopupMenuItem<String>(
                      value: 'report',
                      child: Row(
                        children: const [
                          Icon(Icons.report, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Yorumu Şikayet Et'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(
                5,
                (index) => Icon(
                  index < (comment.rating ?? 0) ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
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
