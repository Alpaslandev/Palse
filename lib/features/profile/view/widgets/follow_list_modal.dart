import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';

// Takipçi/takip listesi modal'ını gösteren widget
class FollowListModal extends StatelessWidget {
  final String title;
  final List<String> userIds;
  final bool showFollowButton;
  final CustomerService _customerService = CustomerService();
  final Function(String userId) onNavigateTap;

  FollowListModal({
    super.key,
    required this.title,
    required this.userIds,
    this.showFollowButton = true,
    required this.onNavigateTap,
  });

  // Static metod ile modal'ı gösterme
  static void show({
    required BuildContext context,
    required String title,
    required List<String> userIds,
    bool showFollowButton = true,
    required Function(String userId) onNavigateTap,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FollowListModal(
        title: title,
        userIds: userIds,
        showFollowButton: showFollowButton,
        onNavigateTap: onNavigateTap,
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
                  : FutureBuilder<List<Customer>>(
                      future: _customerService.getUsersByIds(userIds),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              context.tr('error_loading_users'),
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          );
                        }

                        final customers = snapshot.data ?? [];

                        if (customers.isEmpty) {
                          return _buildEmptyState(context);
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: customers.length,
                          itemBuilder: (context, index) => _buildUserListItem(
                            context,
                            customers[index],
                          ),
                        );
                      },
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
            context.tr('no_one_yet'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  // Kullanıcı liste öğesi
  Widget _buildUserListItem(BuildContext context, Customer customer) {
    return ListTile(
      leading: CircleProfilePicture(
        radius: 20,
        imageUrl: customer.profilePictureUrl ?? '',
      ),
      title: Text(
        customer.fullName().trim().isNotEmpty
            ? customer.fullName()
            : customer.nickname ?? context.tr('anonymous_user'),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: customer.nickname != null && customer.nickname!.isNotEmpty
          ? Text('@${customer.nickname}')
          : null,
      trailing: IconButton(
        onPressed: () {
          Navigator.of(context).pop(); // Modal'ı kapat

          onNavigateTap(customer.userID!);
        },
        icon: const Icon(Icons.arrow_forward_ios),
      ),
      onTap: () {
        // Kullanıcı profiline git
        Navigator.of(context).pop(); // Modal'ı kapat
        // TODO: Profil sayfasına yönlendirme eklenebilir
        onNavigateTap(customer.userID!);

        debugPrint('Kullanıcı profiline git: ${customer.userID}');
      },
    );
  }
}
