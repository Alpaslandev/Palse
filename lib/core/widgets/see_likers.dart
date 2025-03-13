import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/core/widgets/premium_overlay.dart';

class SeeLikersView extends StatelessWidget {
  const SeeLikersView({super.key, required this.viewers});
  final List<String> viewers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beğenenler'),
      ),
      body: PremiumOverlay(
        child: viewers.isEmpty
            ? const Center(child: Text('Henüz beğenen yok'))
            : Material(
                child: ListView.builder(
                  itemCount: viewers.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    return Material(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: FutureBuilder<Customer?>(
                          future: CustomerService().fetchUserFromFirestore(viewers[index]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
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
                              onTap: () => context.pushNamed(friendProfile, extra: user.userID),
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
