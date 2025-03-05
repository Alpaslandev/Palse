import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/widgets/advert_card.dart';
import 'package:palseapp/core/widgets/premium_overlay.dart';
import 'package:palseapp/core/widgets/recently_viewer.dart';
import 'package:palseapp/features/my_advert/viewmodel/my_advert_view_model.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/provider/subscription_provider.dart';

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
            body: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                  indicatorWeight: 2,
                  indicatorColor: Colors.blue,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                  ),
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(
                      text: 'İlanlarım',
                      iconMargin: EdgeInsets.zero,
                    ),
                    Tab(
                      text: 'Beğendiklerim',
                      iconMargin: EdgeInsets.zero,
                    ),
                    Tab(
                      text: 'Profilime Bakanlar',
                      iconMargin: EdgeInsets.zero,
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
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
                                return AdvertCard(
                                  advert: advert,
                                  isUserAdvert: true,
                                  onDeleteTap: () {
                                    debugPrint('sil');
                                    //  viewModel.deleteAdvert(advert.advertID);
                                  },
                                  onSeeViewersTap: () {
                                    context.pushNamed(seeViewers, extra: advert.likers);
                                  },
                                );
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
                                  isMyLikes: true,
                                  isLiked: advert.likers.contains(authProvider.user?.userID ?? ''),
                                  onProfileTap: () => context.push(friendProfile, extra: customer),
                                  onMessageTap: () => debugPrint('mesaj'),
                                );
                              },
                            ),
                      // Profilime Bakanlar
                      _buildProfileViewersTab(viewModel, authProvider),
                    ],
                  ),
                ),
              ],
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

  Widget _buildProfileViewersTab(MyAdvertViewModel viewModel, AuthProvider authProvider) {
    final isPremium = context.watch<SubscriptionProvider>().isPremium;

    return PremiumOverlay(
      isPremium: true,
      child: viewModel.recentlyViewed.isEmpty
          ? _buildEmptyAdvert()
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: viewModel.recentlyViewed.length,
              itemBuilder: (context, index) {
                final customer = viewModel.recentlyViewed[index];
                if (customer == null) return const SizedBox();
                return RecentlyViewer(
                  customer: customer,
                  onProfileTap: () => context.push(friendProfile, extra: customer.userID),
                );
              },
            ),
    );
  }
}
