import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart' as Routes;
import 'package:palseapp/core/widgets/advert/advert_card_view.dart';
import 'package:palseapp/core/widgets/advert/advert_card_view_model.dart';
import 'package:palseapp/core/widgets/premium_overlay.dart';
import 'package:palseapp/core/widgets/recently_viewer.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:provider/provider.dart';

class MyAdvertView extends StatefulWidget {
  final int initialTabIndex;

  // Constructor'a başlangıç tab indeksi parametresi ekle
  const MyAdvertView({super.key, this.initialTabIndex = 0});

  @override
  State<MyAdvertView> createState() => _MyAdvertViewState();
}

class _MyAdvertViewState extends State<MyAdvertView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AdvertService _advertService = AdvertService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<
        AuthProvider,
        ({
          List<String>? favoriteAdverts,
          List<String>? joinedAdvertIds,
          List<String>? events,
          List<String>? profileViewers,
        })>(
      selector: (context, authProvider) => (
        favoriteAdverts: authProvider.user?.favoriteAdverts,
        joinedAdvertIds: authProvider.user?.joinedAdvertIds,
        events: authProvider.user?.events,
        profileViewers: authProvider.user?.profileViewers,
      ),
      builder: (context, userLists, child) {
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
                tabs: [
                  Tab(
                    text: context.tr('my_listings'),
                    iconMargin: EdgeInsets.zero,
                  ),
                  Tab(
                    text: context.tr('my_likes'),
                    iconMargin: EdgeInsets.zero,
                  ),
                  Tab(
                    text: context.tr('profile_viewers'),
                    iconMargin: EdgeInsets.zero,
                  ),
                  Tab(
                    text: context.tr('joined_events'),
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
                    _buildAdvertList(userLists.events ?? []),
                    // Beğendiklerim
                    _buildAdvertList(userLists.favoriteAdverts ?? []),
                    // Profilime Bakanlar
                    _buildProfileViewersTab(context.read<AuthProvider>()),
                    // Katıldığım etkinlikler
                    _buildAdvertList(userLists.joinedAdvertIds ?? []),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ID listesinden AdvertCardView listesi oluşturan widget
  Widget _buildAdvertList(List<String> advertIds) {
    if (advertIds.isEmpty) {
      return _buildEmptyAdvert();
    }

    return ListView.builder(
      itemCount: advertIds.length,
      itemBuilder: (context, index) {
        final advertId = advertIds[index];
        return FutureBuilder<Advert?>(
          future: _advertService.fetchAdvertById(advertId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data == null) {
              return const SizedBox(); // Hatalı veya null veri durumunda boş widget döndür
            }

            return AdvertCardView(
              advert: snapshot.data!,
              mode: AdvertCardMode.myAdvert,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyAdvert() {
    return Center(
      child: Text(context.tr('no_listing_found')),
    );
  }

  Widget _buildProfileViewersTab(AuthProvider authProvider) {
    return PremiumOverlay(
      child: authProvider.user?.profileViewers?.isEmpty ?? true
          ? _buildEmptyAdvert()
          : RecentlyViewer(
              viewers: authProvider.user?.profileViewers ?? [],
              onProfileTap: () => context.pushNamed(Routes.friendProfile,
                  extra: authProvider.user?.userID),
            ),
    );
  }
}
