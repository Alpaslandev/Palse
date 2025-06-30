import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';

// Profil başlığı widget'ı
class ProfileHeader extends StatelessWidget {
  final Customer user;

  const ProfileHeader({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        CircleProfilePicture(
          radius: 30,
          imageUrl: user.profilePictureUrl ?? '',
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${user.fullName()} (${user.getAge()})',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 2),
                if (user.isPremium == true)
                  const Icon(Icons.verified, color: Colors.yellow, size: 16),
                if (user.verification == true)
                  Icon(Icons.verified, color: colorScheme.primary, size: 16),
                IconButton(
                  icon: Icon(Icons.settings_outlined,
                      color: colorScheme.onSurface),
                  onPressed: () {
                    context.pushNamed(settings);
                  },
                ),
              ],
            ),
            Text(
              '@${user.nickname}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
