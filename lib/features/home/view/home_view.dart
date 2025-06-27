import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/advert/advert_card_view.dart';
import 'package:palseapp/core/widgets/advert/advert_card_view_model.dart';
import 'package:palseapp/features/home/viewmodel/home_view_model.dart';
import 'package:palseapp/features/home/widgets/explore_tab_bar.dart';
import 'package:palseapp/features/story/view/storys_view.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  final int initialTabIndex;
  const HomeView({super.key, this.initialTabIndex = 0});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late TabController _topTabController;
  late TabController _exploreTabController;
  late HomeViewModel _viewModel;

  // Kullanıcı verilerini saklayacağız
  late final Customer _user;

  @override
  void initState() {
    super.initState();
    _topTabController = TabController(length: 3, vsync: this);
    _exploreTabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _viewModel = HomeViewModel();
    _topTabController.addListener(_onTopTabChanged);
    _exploreTabController.addListener(_onExploreTabChanged);

    // İlk yüklemeyi yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Kullanıcının sadece ID'sini kaydet
      final authProvider = context.read<AuthProvider>();
      _user = authProvider.user!;

      // İlanları yükle
      if (authProvider.user != null) {
        _viewModel.fetchAdvertsForTab(_user, _exploreTabController.index);
      }
    });
  }

  void _onTopTabChanged() {
    if (!_topTabController.indexIsChanging) {
      // Üst tab değiştiğinde gerekli işlemler
      if (_topTabController.index == 0) {
        // Keşfet sekmesine geçildi, mevcut explore tab'ına göre yükle
        _viewModel.fetchAdvertsForTab(_user, _exploreTabController.index);
      } else {
        // Takiptekiler veya Organizasyonlar sekmesi - şimdilik boş
        // Bu kısımları daha sonra implement edebilirsiniz
      }
    }
  }

  void _onExploreTabChanged() {
    if (!_exploreTabController.indexIsChanging &&
        _topTabController.index == 0) {
      _viewModel.fetchAdvertsForTab(_user, _exploreTabController.index);
    }
  }

  @override
  void dispose() {
    _topTabController.dispose();
    _exploreTabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  // NestedScrollView için sayfalama kontrolü
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent - 500 &&
          !_viewModel.isLoading &&
          _viewModel.hasMore) {
        _viewModel.loadMore(_user, _exploreTabController.index);
      }
    }
    return false;
  }

  Widget _buildExploreContent() {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              ExploreTabBar(controller: _exploreTabController),
              Expanded(
                child: viewModel.isLoading && viewModel.adverts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : viewModel.adverts.isEmpty
                        ? viewModel.shouldShowOtherTab
                            ? Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _exploreTabController.index == 0
                                                ? context.tr(
                                                    'no_listings_in_your_city')
                                                : context.tr(
                                                    'no_listings_in_your_interests'),
                                            textAlign: TextAlign.center,
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () {
                                              _exploreTabController
                                                  .animateTo(2);
                                            },
                                            child: Text(
                                              context.tr(
                                                  'click_to_see_other_listings'),
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(child: Text(context.tr('no_listings_yet')))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80, top: 12),
                            itemCount: viewModel.adverts.length + 1,
                            itemBuilder: (context, index) {
                              if (index == viewModel.adverts.length) {
                                if (viewModel.isLoading) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }

                                if ((!viewModel.hasMore &&
                                        _exploreTabController.index != 2) ||
                                    viewModel.shouldShowOtherTab) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              viewModel.shouldShowOtherTab
                                                  ? (_exploreTabController
                                                              .index ==
                                                          0
                                                      ? context.tr(
                                                          'no_listings_in_your_city')
                                                      : context.tr(
                                                          'no_listings_in_your_interests'))
                                                  : context.tr(
                                                      'no_more_listings_in_category'),
                                              textAlign: TextAlign.center,
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            const SizedBox(height: 8),
                                            TextButton(
                                              onPressed: () {
                                                _exploreTabController
                                                    .animateTo(2);
                                              },
                                              child: Text(
                                                context.tr(
                                                    'click_to_see_other_listings'),
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return const SizedBox.shrink();
                              }

                              final advert = viewModel.adverts[index];

                              if (advert.creatorUserID == _user.userID ||
                                  (_user.blockUsers != null &&
                                      _user.blockUsers!
                                          .contains(advert.creatorUserID))) {
                                if (index >= viewModel.adverts.length - 5 &&
                                    viewModel.hasMore &&
                                    !viewModel.isLoading) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    viewModel.loadMore(
                                        _user, _exploreTabController.index);
                                  });
                                }
                                return const SizedBox.shrink();
                              }

                              return AdvertCardView(
                                advert: advert,
                                mode: AdvertCardMode.home,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFollowingContent() {
    return const Center(
      child: Text(
        'Takiptekiler',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildOrganizationsContent() {
    return const Center(
      child: Text(
        'Organizasyonlar',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Hikayeler için SliverToBoxAdapter
            const SliverToBoxAdapter(
              child: StorysView(),
            ),
            // TabBar için SliverPersistentHeader
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                tabBar: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _topTabController,
                          isScrollable: false,
                          padding: EdgeInsets.zero,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 13,
                          ),
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: 'Keşfet', iconMargin: EdgeInsets.zero),
                            Tab(
                                text: 'Takiptekiler',
                                iconMargin: EdgeInsets.zero),
                            Tab(
                                text: 'Şehrimde Ne Var',
                                iconMargin: EdgeInsets.zero),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          context.pushNamed(filter);
                        },
                        icon: SvgPicture.asset(
                          'assets/vectors/filter_x2.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                              AppTheme.primaryColor, BlendMode.srcIn),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _topTabController,
          children: [
            _buildExploreContent(),
            _buildFollowingContent(),
            _buildOrganizationsContent(),
          ],
        ),
      ),
    );
  }
}

// TabBar için özel delegate sınıfı
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;

  _TabBarDelegate({required this.tabBar});

  @override
  Widget build(context, double shrinkOffset, bool overlapsContent) {
    return tabBar;
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
