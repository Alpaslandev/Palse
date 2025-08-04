import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/routes/routes.dart' as Routes;
import 'package:palseapp/features/matching/match_model.dart';

// Eşleşme listesi item'ını gösteren widget.
class MatchListItemWidget extends StatelessWidget {
  final MatchModel match;

  const MatchListItemWidget({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final double progressValue = (match.score / 140.0).clamp(0.0, 1.0);
    final int percentage = (progressValue * 100).round();
    final Color progressColor = _getProgressColor(percentage);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          context.pushNamed(Routes.friendProfile, extra: match.uid);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Kullanıcı fotoğrafı ve progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  // Progress ring
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  // Kullanıcı fotoğrafı
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: match.photoUrl != null
                          ? Image.network(
                              match.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  // Yüzdelik badge'i fotoğrafın üstünde
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '%$percentage',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Kullanıcı adı
              Text(
                match.name ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Eşleşme metni
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: progressColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getMatchText(percentage),
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              // Eşleşme tarihi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat.yMd().format(match.matchedAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Progress değerine göre renk döndürür
  Color _getProgressColor(int percentage) {
    if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.orange;
    } else if (percentage >= 40) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  // Eşleşme yüzdesine göre metin döndürür
  String _getMatchText(int percentage) {
    if (percentage >= 80) {
      return 'Mükemmel eşleşme!';
    } else if (percentage >= 60) {
      return 'Harika eşleşme';
    } else if (percentage >= 40) {
      return 'İyi eşleşme';
    } else {
      return 'Düşük eşleşme';
    }
  }
}
