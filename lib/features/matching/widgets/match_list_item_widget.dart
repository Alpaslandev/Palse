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
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: match.photoUrl != null ? NetworkImage(match.photoUrl!) : null,
          child: match.photoUrl == null ? const Icon(Icons.person, size: 28) : null,
        ),
        title: Text(
          match.name ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (match.score / 140.0).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ),
                      minHeight: 3.0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '%${((match.score / 140.0) * 100).clamp(0, 100).round()}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMd().format(match.matchedAt),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: () {
          context.pushNamed(Routes.friendProfile, extra: match.uid);
        },
      ),
    );
  }
}
