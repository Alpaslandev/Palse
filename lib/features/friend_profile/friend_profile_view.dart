import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/services/chat_service.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/advert/advert_card_view.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';
import 'package:palseapp/features/friend_profile/friend_profile_view_model.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/features/achievement/achievement_service.dart';
import 'package:palseapp/core/widgets/advert/advert_card_view_model.dart';

class FriendProfileView extends StatelessWidget {
  const FriendProfileView({super.key, required this.customerID});
  final String customerID;

  @override
  Widget build(BuildContext context) {
    final userID = context.read<AuthProvider>().user!.userID;
    return ChangeNotifierProvider<FriendProfileViewModel>(
      create: (context) => FriendProfileViewModel(
          customerID: customerID, authProvider: context.read<AuthProvider>()),
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
                            Text(
                                '${context.tr('listings')} (${viewModel.adverts.length})',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  debugPrint(
                                      'İlan gösteriliyor: ${viewModel.adverts[index].toString()}');
                                  return AdvertCardView(
                                    advert: viewModel.adverts[index],
                                    mode: AdvertCardMode.friendProfile,
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
                        onPressed: () async {
                          final ChatService chatsService = ChatService();

                          final chatId = await chatsService.startOrGetChat(
                            customerID,
                            userID!,
                          );

                          if (context.mounted) {
                            context.push(
                                '/chats/$chatId?otherId=$customerID&currentId=$userID');
                          }
                        },
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
    final authProvider = context.read<AuthProvider>();
    final achievementService = AchievementService();

    if (viewModel.customer == null) {
      return const SizedBox.shrink();
    }

    final xp = viewModel.customer!.totalXp;
    final rank = achievementService.getUserRankFromXp(xp);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${rank.icon} ${achievementService.getLocalizedRankTitle(rank, context)} ($xp XP)',
          style: TextStyle(
              fontSize: 11,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold),
        ),
        Text(
            viewModel.customer?.location
                    ?.displayStringWithDistance(authProvider.user!.location!) ??
                '',
            style: TextStyle(
              fontSize: 9,
              color: AppTheme.primaryColor,
            )),
      ],
    );
  }

  Widget _profileHeader(
      BuildContext context, FriendProfileViewModel viewModel) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Text(
              '${viewModel.customer?.firstName!} (${viewModel.customer?.getAge()})'),
          if (viewModel.customer?.verification == true &&
              viewModel.customer?.phoneNumber != null)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.verified, color: Colors.blue, size: 16),
            ),
        ],
      ),
      subtitle: Text(viewModel.customer?.nickname ?? ''),
      leading: CircleProfilePicture(
        imageUrl: viewModel.customer?.profilePictureUrl ?? '',
      ),
      trailing: PopupMenuButton(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            value: 'report',
            child: ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: Text(context.tr('report_abuse')),
              onTap: () async {
                context.pop();

                // Rapor açıklaması için dialog göster
                final TextEditingController reportController =
                    TextEditingController();
                String? reportReason;

                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.tr('report_abuse')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(context.tr('please_explain_reason')),
                          const SizedBox(height: 16),
                          TextField(
                            controller: reportController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: context.tr('report_reason_hint'),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(context.tr('cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            reportReason = reportController.text;
                            context.pop();
                          },
                          child: Text(context.tr('submit')),
                        ),
                      ],
                    ),
                  );
                }

                // Eğer açıklama varsa rapor et
                if (reportReason != null &&
                    reportReason!.isNotEmpty &&
                    context.mounted) {
                  try {
                    await viewModel.reportUser(reportReason!);
                    if (context.mounted) {
                      ScaffoldMess.showSuccessSnackBar(
                          context.tr('report_sent'));
                      context.go('/home');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMess.showErrorSnackBar(
                          context.tr('error_occurred'));
                    }
                  }
                }
              },
            ),
          ),
          PopupMenuItem(
            value: 'block',
            child: ListTile(
              leading: Icon(
                  viewModel.isUserBlocked() ? Icons.person_add : Icons.block,
                  color: Colors.red),
              title: Text(viewModel.isUserBlocked()
                  ? context.tr('unblock_user')
                  : context.tr('block_user')),
              onTap: () async {
                context.pop();

                try {
                  await viewModel.toggleBlockUser();

                  if (context.mounted) {
                    if (viewModel.isUserBlocked()) {
                      ScaffoldMess.showSuccessSnackBar(
                          context.tr('user_blocked'));
                      context.go('/home');
                    } else {
                      ScaffoldMess.showSuccessSnackBar(
                          context.tr('user_unblocked'));
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMess.showErrorSnackBar(
                        context.tr('error_occurred'));
                  }
                }
              },
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
                Text(
                    '${context.tr('comments')} (${viewModel.customer?.comments?.length ?? 0})'),
              ],
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            border: Border(
                left: BorderSide(
                    color: Colors.grey,
                    width: 1)), // Sol kenara gri çizgi ekleniyor
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              viewModel.customer?.getAverage().toStringAsFixed(1) ?? '0.0',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
          ),
        ),
      ));
}
