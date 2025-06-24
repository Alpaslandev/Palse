import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/core/widgets/premium_overlay.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';

class UserListView extends StatelessWidget {
  const UserListView({
    super.key,
    required this.users,
    this.isLikers = false,
    this.advertId,
  });
  final List<String> users;
  final bool isLikers;
  final String? advertId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(isLikers ? context.tr('likers') : context.tr('join_request')),
      ),
      body: PremiumOverlay(
        child: users.isEmpty
            ? Center(
                child: Text(isLikers
                    ? 'Henüz beğenen yok'
                    : 'Henüz katılım isteği yok'),
              )
            : Material(
                child: ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    return Material(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: FutureBuilder<Customer?>(
                          future: CustomerService()
                              .fetchUserFromFirestore(users[index]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const ListTile(
                                leading: CircularProgressIndicator(),
                                title: Text('Yükleniyor...'),
                              );
                            }

                            if (snapshot.hasError) {
                              return ListTile(
                                leading: const Icon(Icons.error),
                                title: Text('Hata: ${snapshot.error}'),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const ListTile(
                                leading: Icon(Icons.person_off),
                                title: Text('Kullanıcı bulunamadı'),
                              );
                            }

                            final user = snapshot.data!;
                            return ListTile(
                              leading: CircleProfilePicture(
                                imageUrl: user.profilePictureUrl ?? '',
                              ),
                              title: Text('${user.firstName} ${user.lastName}'),
                              subtitle: Text(user.nickname ?? ''),
                              onTap: () => context.pushNamed(friendProfile,
                                  extra: user.userID),
                              trailing: isLikers
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Reddetme butonu
                                        IconButton(
                                          onPressed: () async {
                                            if (advertId == null) return;
                                            try {
                                              await AdvertService()
                                                  .rejectJoinRequest(
                                                advertId!,
                                                users[index],
                                              );
                                              if (context.mounted) {
                                                ScaffoldMess
                                                    .showSuccessSnackBar(
                                                  'Katılım isteği reddedildi',
                                                );
                                                // Sayfayı yenile
                                                Navigator.of(context).pop();
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMess.showErrorSnackBar(
                                                  'Hata oluştu: $e',
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                          tooltip: 'Reddet',
                                        ),
                                        // Onaylama butonu
                                        IconButton(
                                          onPressed: () async {
                                            if (advertId == null) return;
                                            try {
                                              await AdvertService()
                                                  .acceptJoinRequest(
                                                advertId!,
                                                users[index],
                                              );
                                              if (context.mounted) {
                                                ScaffoldMess
                                                    .showSuccessSnackBar(
                                                  'Katılım isteği onaylandı',
                                                );
                                                // Sayfayı yenile
                                                Navigator.of(context).pop();
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMess.showErrorSnackBar(
                                                  'Hata oluştu: $e',
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          ),
                                          tooltip: 'Onayla',
                                        ),
                                      ],
                                    ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
