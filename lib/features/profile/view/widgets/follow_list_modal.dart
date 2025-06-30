import 'package:flutter/material.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';

// Takipçi/takip listesi modal'ını gösteren widget
class FollowListModal extends StatelessWidget {
  final String title;
  final List<String> userIds;
  final bool showFollowButton;

  const FollowListModal({
    super.key,
    required this.title,
    required this.userIds,
    this.showFollowButton = true,
  });

  // Static metod ile modal'ı gösterme
  static void show({
    required BuildContext context,
    required String title,
    required List<String> userIds,
    bool showFollowButton = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FollowListModal(
        title: title,
        userIds: userIds,
        showFollowButton: showFollowButton,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Modal handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Başlık
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            // Liste içeriği
            Expanded(
              child: userIds.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: userIds.length,
                      itemBuilder: (context, index) => _buildUserListItem(
                        context,
                        userIds[index],
                        index,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Boş durum widget'ı
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz kimse yok',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  // Kullanıcı liste öğesi
  Widget _buildUserListItem(BuildContext context, String userId, int index) {
    // TODO: Gerçek kullanıcı verilerini userId ile çekmek gerekecek
    // Şimdilik placeholder data kullanıyoruz
    return ListTile(
      leading: CircleProfilePicture(
        radius: 20,
        imageUrl: '', // TODO: Gerçek profil resmi URL'i
      ),
      title: Text('Kullanıcı ${index + 1}'), // TODO: Gerçek kullanıcı adı
      subtitle:
          Text('@kullanici${index + 1}'), // TODO: Gerçek kullanıcı nickname
      trailing: showFollowButton
          ? OutlinedButton(
              onPressed: () {
                // TODO: Takip etme/bırakma işlemi
                _handleFollowAction(context, userId);
              },
              child: const Text(
                  'Takip Et'), // TODO: Dinamik metin (Takip Et/Takibi Bırak)
            )
          : null,
    );
  }

  // Takip etme/bırakma işlemi
  void _handleFollowAction(BuildContext context, String userId) {
    // TODO: Takip etme/bırakma servisi ile işlem yapılacak
    debugPrint('Takip işlemi: $userId');

    // Geçici olarak SnackBar göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Takip işlemi: $userId'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
