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

// Ana sayfa view'i - PageView ile animasyonlu tab geçişi
class HomeView extends StatefulWidget {
  final int initialTabIndex;
  const HomeView({super.key, this.initialTabIndex = 0});

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late TabController _topTabController;
  late TabController _exploreTabController;
  late PageController _pageController;
  late HomeViewModel _viewModel;
  late Customer _user;
  bool _isInitialized = false;

  // Her tab için scroll controller'ları
  final List<ScrollController> _scrollControllers = [
    ScrollController(),
    ScrollController(),
    ScrollController(),
  ];

  @override
  void initState() {
    super.initState();
    _topTabController = TabController(length: 1, vsync: this);
    _exploreTabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _pageController = PageController(initialPage: widget.initialTabIndex);
    _viewModel = HomeViewModel();
    _exploreTabController.addListener(_onExploreTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = context.read<AuthProvider>();
      _user = authProvider.user!;

      // İlk tab'ı initialize et
      _viewModel.initializeTab(_user, _exploreTabController.index);
      _isInitialized = true;
    }
  }

  // Tab'e tıklandığında PageView'ı senkronize et ve tab'ı yükle
  void _onExploreTabChanged() {
    // Sadece TabBar'a dokunulduğunda PageView'ı animasyonla değiştir.
    if (_exploreTabController.indexIsChanging) {
      debugPrint('🔄 Tab değişiyor: ${_exploreTabController.index}');
      // jumpToPage kullan - animasyonsuz ama garantili çalışır
      _pageController.jumpToPage(_exploreTabController.index);
    }
    // Yeni seçilen tab'ı yükle.
    _viewModel.initializeTab(_user, _exploreTabController.index);
  }

  // PageView kaydırıldığında TabBar'ı senkronize et.
  void _onPageChanged(int index) {
    debugPrint('📄 PageView değişti: $index');
    if (_exploreTabController.index != index) {
      debugPrint('🔄 TabController güncelleniyor: $index');
      _exploreTabController.index = index;
    }
  }

  // Refresh butonuna basıldığında aktif tab'ı yenile
  void _refreshCurrentTab() async {
    _scrollToTopSmoothly(_exploreTabController.index);
    await Future.delayed(const Duration(milliseconds: 200));
    _viewModel.refreshTab(_user, _exploreTabController.index);
  }

  // Tüm tab'ları yenile
  void _refreshAllTabs() async {
    _scrollToTopSmoothly(_exploreTabController.index);
    await Future.delayed(const Duration(milliseconds: 200));
    _viewModel.refreshAllTabs(_user);
  }

  // Yumuşak kaydırma
  void _scrollToTopSmoothly(int tabIndex) {
    final controller = _scrollControllers[tabIndex];
    if (controller.hasClients) {
      controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _topTabController.dispose();
    _exploreTabController.removeListener(_onExploreTabChanged);
    _exploreTabController.dispose();
    _pageController.dispose();
    _viewModel.dispose();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Basit tab içeriği - performanslı
  Widget _buildTabContent(int tabIndex) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          final adverts = viewModel.getAdvertsForTab(tabIndex);
          final isLoading = viewModel.isTabLoading(tabIndex);
          final isInitialized = viewModel.isTabInitialized(tabIndex);

          if (!isInitialized && isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adverts.isEmpty && !isLoading) {
            return _buildEmptyState(tabIndex);
          }

          return RefreshIndicator(
            onRefresh: () async {
              _scrollToTopSmoothly(tabIndex);
              await Future.delayed(const Duration(milliseconds: 200));
              return _viewModel.refreshTab(_user, tabIndex);
            },
            child: ListView.builder(
              controller: _scrollControllers[tabIndex],
              padding: const EdgeInsets.only(bottom: 80, top: 12),
              itemCount: adverts.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == adverts.length && isLoading) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  );
                }

                final advert = adverts[index];

                if (advert.creatorUserID == _user.userID ||
                    (_user.blockUsers != null &&
                        _user.blockUsers!.contains(advert.creatorUserID))) {
                  return const SizedBox.shrink();
                }

                // Basit AdvertCardView - performanslı
                return AdvertCardView(
                  advert: advert,
                  mode: AdvertCardMode.home,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Boş durum widget'ı
  Widget _buildEmptyState(int tabIndex) {
    String message;
    switch (tabIndex) {
      case 0:
        message = context.tr('no_listings_in_your_city');
        break;
      case 1:
        message = context.tr('no_listings_in_your_interests');
        break;
      case 2:
        message = context.tr('no_other_listings');
        break;
      default:
        message = context.tr('no_listings_yet');
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (tabIndex != 2)
                  TextButton(
                    onPressed: () => _exploreTabController.animateTo(2),
                    child: Text(
                      context.tr('click_to_see_other_listings'),
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
    );
  }

  Widget _buildExploreContent() {
    return Column(
      children: [
        ExploreTabBar(controller: _exploreTabController),
        Expanded(
          // PageView ile animasyonlu geçiş - sadece tab'lara tıklanarak geçiş
          child: PageView(
            controller: _pageController,
            physics:
                const NeverScrollableScrollPhysics(), // Parmakla kaydırmayı engelle
            onPageChanged: _onPageChanged,
            children: [
              _buildTabContent(0),
              _buildTabContent(1),
              _buildTabContent(2),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          const SliverToBoxAdapter(
            child: StorysView(),
          ),
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
                        isScrollable: true,
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        indicatorWeight: 3,
                        tabAlignment: TabAlignment.start,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: const TextStyle(fontSize: 13),
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: 'Keşfet', iconMargin: EdgeInsets.zero),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _refreshCurrentTab,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Yenile',
                    ),
                    IconButton(
                      onPressed: () => context.pushNamed(filter),
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
        ],
      ),
    );
  }

  void refreshFromNavigation() {
    _refreshAllTabs();
  }
}

// TabBar delegate
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
