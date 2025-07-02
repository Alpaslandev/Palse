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
import 'package:palseapp/core/keys/global_keys.dart';
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

  @override
  void initState() {
    super.initState();
    _exploreTabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTabIndex);
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
      setState(() {});
      _viewModel.initializeTab(_user, _exploreTabController.index);
    }
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
                  minHeight: 115,
                  maxHeight: 115,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDiscoverHeader(),
                        ExploreTabBar(controller: _exploreTabController),
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
          Text(context.tr('discover'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    _viewModel.refreshTab(_user, _exploreTabController.index),
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
        ],
      ),
    );
  }

  Widget _buildSliverContentForTab() {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
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
                if (advert.creatorUserID == _user.userID ||
                    (_user.blockUsers != null &&
                        _user.blockUsers!.contains(advert.creatorUserID))) {
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
        child: Text(message,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

// refreshFromNavigation metodunu HomeView'ın dışına taşıdık veya kaldırdık
// Eğer hala bir yerden çağrılıyorsa, GlobalKey kullanarak HomeViewState'e erişmek gerekir.
// Örneğin: final GlobalKey<HomeViewState> homeViewKey = GlobalKey<HomeViewState>();
// homeViewKey.currentState?.refreshFromNavigation();
// Şimdilik bu metodu yorum satırına alıyorum.
/*
void refreshFromNavigation() {
  // Bu metoda erişim için GlobalKey kullanılması gerekir.
}
*/
