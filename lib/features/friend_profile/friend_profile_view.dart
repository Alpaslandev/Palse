import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/widgets/advert/advert_card.dart';
import 'package:palseapp/features/friend_profile/friend_profile_view_model.dart';
import 'package:provider/provider.dart';

class FriendProfileView extends StatelessWidget {
  const FriendProfileView({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FriendProfileViewModel(customer: customer),
      child: Consumer<FriendProfileViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(),
            body: Column(
              children: [
                ListTile(
                  title: Text('${customer.firstName!} (${customer.age.toString()})'),
                  subtitle: Text(customer.nickname ?? ''),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(customer.profilePictureUrl ?? ""),
                  ),
                  trailing: const Icon(Icons.more_vert),
                ),
                _ratingCard(customer.average ?? 0),
                Text('İlanlar (${viewModel.adverts.length})'),
                const SizedBox(height: 16),
                Expanded(
                  child: viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : viewModel.adverts.isEmpty
                          ? const Center(child: Text('Henüz ilan bulunmuyor'))
                          : ListView.builder(
                              itemCount: viewModel.adverts.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                debugPrint('İlan gösteriliyor: ${viewModel.adverts[index].toString()}');
                                return AdvertCard(
                                  advert: viewModel.adverts[index],
                                  customer: customer,
                                  isFriendProfile: true,
                                );
                              },
                            ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {},
                  child: const Text('Mesaj Gönder'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Yorumlar kartı
Widget _ratingCard(double rating) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              Text('Yorumlar'),
            ],
          ),
          Text('0.0'),
        ],
      ),
    ),
  );
}
