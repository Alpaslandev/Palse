import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/widgets/advert/advert_card.dart';
import 'package:palseapp/features/friend_profile/friend_profile_view_model.dart';
import 'package:provider/provider.dart';

class FriendProfileView extends StatelessWidget {
  const FriendProfileView({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    debugPrint(customer.userID);
    return ChangeNotifierProvider(
      create: (context) => FriendProfileViewModel(customer: customer),
      child: Consumer<FriendProfileViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _profileHeader(),
                  _ratingCard(viewModel, context),
                  const SizedBox(height: 16),
                  Text('İlanlar (${viewModel.adverts.length})'),
                  Expanded(
                    child: viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : viewModel.adverts.isEmpty
                            ? const Center(child: Text('Henüz ilan bulunmuyor'))
                            : ListView.builder(
                                padding: EdgeInsets.zero,
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
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _messageButton(),
              ),
            ),
          );
        },
      ),
    );
  }

  ElevatedButton _messageButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      onPressed: () {},
      child: const Text('Mesaj Gönder'),
    );
  }

  Widget _profileHeader() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Text('${customer.firstName!} (${customer.age.toString()})'),
          if (customer.verification == true && customer.phoneNumber != null)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.verified, color: Colors.blue, size: 16),
            ),
        ],
      ),
      subtitle: Text(customer.nickname ?? ''),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(customer.profilePictureUrl ?? ""),
      ),
      trailing: PopupMenuButton(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            value: 'report',
            child: ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Kötüye Kullanım Bildir'),
            ),
          ),
          PopupMenuItem(
            value: 'block',
            child: ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Kullanıcıyı Engelle'),
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
                Text('Yorumlar (${viewModel.customer.comments?.length ?? 0})'),
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
              viewModel.customer.getAverage().toStringAsFixed(1),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),
        ),
      ));
}
