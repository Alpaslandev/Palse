import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/provider/subscription_provider.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/widgets/premium_overlay.dart';
import 'package:provider/provider.dart';

class SeeLikersView extends StatelessWidget {
  const SeeLikersView({super.key, required this.viewers});
  final List<String> viewers;

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<SubscriptionProvider>().isPremium;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beğenenler'),
      ),
      body: PremiumOverlay(
        isPremium: context.watch<AuthProvider>().user?.isPremium ?? false,
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
                        child: StreamBuilder<Customer?>(
                          // Stream'i CustomerService'den alıyoruz
                          stream: CustomerService().getUserStream(viewers[index]),
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
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                  user.profilePictureUrl ?? '',
                                ),
                              ),
                              title: Text('${user.firstName} ${user.lastName}'),
                              subtitle: Text(user.nickname ?? ''),
                              onTap: () => context.push('/friendProfile', extra: user),
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
