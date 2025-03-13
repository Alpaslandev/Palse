import 'package:flutter/material.dart';
import 'package:palseapp/core/models/comment_model.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/core/localization/app_localizations.dart';

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
                      _showReportConfirmation(context);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    // Yorumu yapan kişi veya yorumun yapıldığı profil sahibi ise silme butonu gösterilir
                    if (comment.commenterID == currentUserId || profileOwnerId == currentUserId)
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(context.tr('delete')),
                          ],
                        ),
                      ),
                    // Kendi yorumunu şikayet edemez
                    if (comment.commenterID != currentUserId)
                      PopupMenuItem<String>(
                        value: 'report',
                        child: Row(
                          children: [
                            const Icon(Icons.report, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(context.tr('report_abuse')),
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

  // Şikayet onayı için dialog göster
  void _showReportConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('report_abuse')),
        content: Text(context.tr('please_explain_reason')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onReportTap();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(context.tr('submit')),
          ),
        ],
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
