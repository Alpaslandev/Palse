import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/advert/advert_card_view.dart';
import 'package:palseapp/core/widgets/advert/advert_card_view_model.dart';
import 'package:palseapp/core/keys/global_keys.dart';
import 'package:palseapp/features/city_events/view/city_events_view.dart';
import 'package:palseapp/features/home/viewmodel/home_view_model.dart';
import 'package:palseapp/features/home/widgets/explore_tab_bar.dart';
import 'package:palseapp/features/story/view/storys_view.dart';
import 'package:provider/provider.dart';

// Ana sayfa view'i - Instagram tarzı tek scroll ve sticky header
class HomeView extends StatefulWidget {
  final int initialTabIndex;
  const HomeView({super.key, this.initialTabIndex = 0});

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late TabController _exploreTabController;
  late HomeViewModel _viewModel;
  late Customer _user;
  bool _isInitialized = false;
  final ScrollController _scrollController = ScrollController();

  // Ana başlık seçimi için
  int _selectedHeaderIndex = 0;

  @override
  void initState() {
    super.initState();
    _exploreTabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _viewModel = HomeViewModel();
    _exploreTabController.addListener(_onExploreTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = context.read<AuthProvider>();
      _user = authProvider.user!;
      _viewModel.initializeTab(_user, _exploreTabController.index);
      _isInitialized = true;
    }
  }

  void _onExploreTabChanged() {
    if (_exploreTabController.indexIsChanging) {
      setState(() {
        // Tab değişikliğinde UI'ı güncelle
      });
      _viewModel.initializeTab(_user, _exploreTabController.index);
    }
  }

  // Ana başlık seçimi değiştiğinde çağrılır
  void _onHeaderSelected(int index) {
    setState(() {
      _selectedHeaderIndex = index;
    });
  }

  Future<void> _refreshData() async {
    _scrollToTopSmoothly();
    // Hikayeleri yenile
    GlobalKeys.instance.storysViewKey.currentState?.refreshStories();
    await _viewModel.refreshAllTabs(_user);
  }

  void _scrollToTopSmoothly() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _exploreTabController.removeListener(_onExploreTabChanged);
    _exploreTabController.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChangeNotifierProvider.value(
        value: _viewModel,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: StorysView(key: GlobalKeys.instance.storysViewKey),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  minHeight: _selectedHeaderIndex == 0 ? 115 : 70,
                  maxHeight: _selectedHeaderIndex == 0 ? 115 : 70,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDiscoverHeader(),
                        // Sadece Keşfet başlığı seçiliyken ExploreTabBar'ı göster
                        if (_selectedHeaderIndex == 0) ExploreTabBar(controller: _exploreTabController),
                      ],
                    ),
                  ),
                ),
              ),
              _buildSliverContentForTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tab container - resimdeki gibi yuvarlak köşeli tab tasarımı
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildTabItem(
                      text: context.tr("home_header_explore"),
                      isSelected: _selectedHeaderIndex == 0,
                      onTap: () => _onHeaderSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _buildTabItem(
                      text: context.tr("home_header_following"),
                      isSelected: _selectedHeaderIndex == 1,
                      onTap: () => _onHeaderSelected(1),
                    ),
                  ),
                  Expanded(
                    child: _buildTabItem(
                      text: context.tr("home_header_city_events"),
                      isSelected: _selectedHeaderIndex == 2,
                      onTap: () => _onHeaderSelected(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.pushNamed(filter),
            icon: SvgPicture.asset(
              'assets/vectors/filter_x2.svg',
              width: 18,
              height: 18,
              colorFilter: const ColorFilter.mode(AppTheme.primaryColor, BlendMode.srcIn),
            ),
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  // Tab item widget'ı - resimdeki gibi aktif/pasif durumları için
  Widget _buildTabItem({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSelected ? 12 : 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverContentForTab() {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        // Ana başlık seçimine göre içerik göster
        if (_selectedHeaderIndex == 0) {
          // Keşfet başlığı - ExploreTabBar içeriği
          final tabIndex = _exploreTabController.index;
          final adverts = viewModel.getAdvertsForTab(tabIndex);
          final isLoading = viewModel.isTabLoading(tabIndex);
          final isInitialized = viewModel.isTabInitialized(tabIndex);

          if (!isInitialized && isLoading) {
            return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (adverts.isEmpty) {
            return SliverFillRemaining(
              child: _buildEmptyState(tabIndex),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == adverts.length) {
                    return isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }
                  final advert = adverts[index];
                  if (advert.creatorUserID == _user.userID || (_user.blockUsers != null && _user.blockUsers!.contains(advert.creatorUserID))) {
                    return const SizedBox.shrink();
                  }
                  return AdvertCardView(
                    key: ValueKey('${advert.advertID}_tab_$tabIndex'),
                    advert: advert,
                    mode: AdvertCardMode.home,
                  );
                },
                childCount: adverts.length + 1,
              ),
            ),
          );
        } else if (_selectedHeaderIndex == 1) {
          // Takiptekiler başlığı - takip edilen kişilerin ilanları
          return FutureBuilder<List<Advert>>(
            future: viewModel.loadFollowingsAdverts(_user),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      context.tr('home_error_message').replaceAll('{error}', snapshot.error.toString()),
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final adverts = snapshot.data ?? [];

              if (adverts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppTheme.primaryColor),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('home_following_title'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('home_following_empty_message'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Takip edilen kişilerin ilanlarını göster
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final advert = adverts[index];
                      return AdvertCardView(
                        key: ValueKey('${advert.advertID}_following'),
                        advert: advert,
                        mode: AdvertCardMode.home,
                      );
                    },
                    childCount: adverts.length,
                  ),
                ),
              );
            },
          );
        } else {
          // Şehrimde Ne Var başlığı - CityEventsView
          return SliverFillRemaining(
            child: CityEventsView(user: _user),
          );
        }
      },
    );
  }

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
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
  }
}
