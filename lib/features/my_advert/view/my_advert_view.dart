import 'package:flutter/material.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/widgets/advert/advert_card.dart';
import 'package:palseapp/core/widgets/advert/advert_detail.dart';
import 'package:palseapp/features/friend_profile/friend_profile_view.dart';
import 'package:palseapp/features/my_advert/viewmodel/my_advert_view_model.dart';
import 'package:provider/provider.dart';

class MyAdvertView extends StatefulWidget {
  const MyAdvertView({super.key});

  @override
  State<MyAdvertView> createState() => _MyAdvertViewState();
}

class _MyAdvertViewState extends State<MyAdvertView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return ChangeNotifierProvider<MyAdvertViewModel>(
      create: (context) => MyAdvertViewModel(authProvider: authProvider),
      child: Consumer<MyAdvertViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'İlanlarım'),
                Tab(text: 'Beğendiklerim'),
                Tab(text: 'Son Baktıklarım'),
              ],
            ),
            body: Consumer<MyAdvertViewModel>(
              builder: (context, viewModel, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // İlanlarım sekmesi
                    viewModel.myAdverts.isEmpty
                        ? _buildEmptyAdvert()
                        : ListView.builder(
                            itemCount: viewModel.myAdverts.length,
                            itemBuilder: (context, index) {
                              final advert = viewModel.myAdverts[index];
                              final customer = authProvider.user;
                              if (advert == null) return const SizedBox();
                              return AdvertCard(advert: advert, isUserAdvert: true, customer: customer!);
                            },
                          ),
                    // Beğendiklerim
                    viewModel.favorites.isEmpty
                        ? _buildEmptyAdvert()
                        : ListView.builder(
                            itemCount: viewModel.favorites.length,
                            itemBuilder: (context, index) {
                              debugPrint(viewModel.favorites.length.toString());
                              final advert = viewModel.favorites[index];
                              final customer = viewModel.getCustomerForAdvert(advert);
                              if (advert == null) return const SizedBox();
                              return AdvertCard(
                                  advert: advert,
                                  customer: customer!,
                                  onProfileTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => FriendProfileView(customer: customer)),
                                    );
                                  },
                                  onAdvertDetailTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AdvertDetail(advert: advert)),
                                    );
                                  });
                            },
                          ),
                    // Son Baktıklarım
                    viewModel.favorites.isEmpty
                        ? _buildEmptyAdvert()
                        : ListView.builder(
                            itemCount: viewModel.favorites.length,
                            itemBuilder: (context, index) {
                              final advert = viewModel.favorites[index];
                              final customer = viewModel.getCustomerForAdvert(advert);
                              if (advert == null) return const SizedBox();
                              return AdvertCard(
                                  advert: advert,
                                  customer: customer!,
                                  onProfileTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => FriendProfileView(customer: customer)),
                                    );
                                  },
                                  onAdvertDetailTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AdvertDetail(advert: advert)),
                                    );
                                  });
                            },
                          ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyAdvert() {
    return const Center(
      child: Text('İlan bulunamadı'),
    );
  }
}
