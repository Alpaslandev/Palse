import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/advert_card.dart';
import 'package:palseapp/features/achievement/user_achievements.dart';
import 'package:palseapp/features/friend_profile/friend_profile_view_model.dart';
import 'package:provider/provider.dart';

class FriendProfileView extends StatelessWidget {
  const FriendProfileView({super.key, required this.customerID});
  final String customerID;

  @override
  Widget build(BuildContext context) {
    debugPrint(customerID);
    return ChangeNotifierProvider(
      create: (context) => FriendProfileViewModel(customerID: customerID),
      child: Consumer<FriendProfileViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _profileHeader(context, viewModel),
                            _subHeader(viewModel, context),
                            _ratingCard(viewModel, context),
                            Divider(),
                            Text('${context.tr('listings')} (${viewModel.adverts.length})',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: viewModel.adverts.isEmpty
                            ? Center(child: Text(context.tr('no_listings_yet')))
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: viewModel.adverts.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  debugPrint('İlan gösteriliyor: ${viewModel.adverts[index].toString()}');
                                  return AdvertCard(
                                    advert: viewModel.adverts[index],
                                    isFriendProfile: true,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
            bottomNavigationBar: viewModel.isLoading
                ? const SizedBox.shrink()
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Text(context.tr('send_message')),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _subHeader(FriendProfileViewModel viewModel, BuildContext context) {
    final userAchievements = UserAchievements(xp: viewModel.customer?.xp ?? 0);
    final authProvider = context.read<AuthProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${userAchievements.rank.icon} ${userAchievements.rank.title} (${userAchievements.xp} XP)',
          style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
        Text(viewModel.customer?.location?.displayStringWithDistance(authProvider.user!.location!) ?? '',
            style: TextStyle(
              fontSize: 9,
              color: AppTheme.primaryColor,
            )),
      ],
    );
  }

  Widget _profileHeader(BuildContext context, FriendProfileViewModel viewModel) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Text('${viewModel.customer?.firstName!} (${viewModel.customer?.getAge()})'),
          if (viewModel.customer?.verification == true && viewModel.customer?.phoneNumber != null)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.verified, color: Colors.blue, size: 16),
            ),
        ],
      ),
      subtitle: Text(viewModel.customer?.nickname ?? ''),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(viewModel.customer?.profilePictureUrl ?? ""),
      ),
      trailing: PopupMenuButton(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            value: 'report',
            child: ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: Text(context.tr('report_abuse')),
            ),
          ),
          PopupMenuItem(
            value: 'block',
            child: ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text(context.tr('block_user')),
            ),
          ),
        ],
      ),
    );
  }
}

// Yorumlar kartı
Widget _ratingCard(FriendProfileViewModel viewModel, BuildContext context) {
  return Card(
      elevation: 4,
      child: ListTile(
        onTap: () => context.pushNamed(comment, extra: viewModel.customer),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                Text('${context.tr('comments')} (${viewModel.customer?.comments?.length ?? 0})'),
              ],
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: Colors.grey, width: 1)), // Sol kenara gri çizgi ekleniyor
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              viewModel.customer?.getAverage().toStringAsFixed(1) ?? '0.0',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
        ),
      ));
}
