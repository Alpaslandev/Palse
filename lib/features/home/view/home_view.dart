import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/advert_card.dart';
import 'package:palseapp/features/home/viewmodel/home_view_model.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  final int initialTabIndex;
  const HomeView({super.key, this.initialTabIndex = 0});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late TabController _tabController;
  late HomeViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();

  // Kullanıcı verilerini saklayacağız
  late final Customer _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _viewModel = HomeViewModel();
    _tabController.addListener(_onTabChanged);

    // Sayfalama için scroll dinleyicisi
    _scrollController.addListener(_onScroll);

    // İlk yüklemeyi yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Kullanıcının sadece ID'sini kaydet
      final authProvider = context.read<AuthProvider>();
      _user = authProvider.user!;

      // İlanları yükle
      if (authProvider.user != null) {
        _viewModel.fetchAdvertsForTab(_user, _tabController.index);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500 && !_viewModel.isLoading && _viewModel.hasMore) {
      _viewModel.loadMore(_user, _tabController.index);
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _viewModel.fetchAdvertsForTab(_user, _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      isScrollable: false,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                      indicatorWeight: 2,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12,
                      ),
                      unselectedLabelColor: Colors.grey,
                      controller: _tabController,
                      tabs: [
                        Tab(text: context.tr('city_based'), iconMargin: EdgeInsets.zero),
                        Tab(text: context.tr('interest_based'), iconMargin: EdgeInsets.zero),
                        Tab(text: context.tr('other'), iconMargin: EdgeInsets.zero),
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
                      colorFilter: const ColorFilter.mode(AppTheme.primaryColor, BlendMode.srcIn),
                    ),
                  ),
                ],
              ),
            ),
            body: viewModel.isLoading && viewModel.adverts.isEmpty
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
                                        _tabController.index == 0
                                            ? context.tr('no_listings_in_your_city')
                                            : context.tr('no_listings_in_your_interests'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton(
                                        onPressed: () {
                                          _tabController.animateTo(2);
                                        },
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
                          )
                        : Center(child: Text(context.tr('no_listings_yet')))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 12),
                        controller: _scrollController,
                        itemCount: viewModel.adverts.length + 1,
                        itemBuilder: (context, index) {
                          if (index == viewModel.adverts.length) {
                            if (viewModel.isLoading) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            if ((!viewModel.hasMore && _tabController.index != 2) || viewModel.shouldShowOtherTab) {
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
                                              ? (_tabController.index == 0
                                                  ? context.tr('no_listings_in_your_city')
                                                  : context.tr('no_listings_in_your_interests'))
                                              : context.tr('no_more_listings_in_category'),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () {
                                            _tabController.animateTo(2);
                                          },
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
                              );
                            }

                            return const SizedBox.shrink();
                          }

                          final advert = viewModel.adverts[index];

                          if (advert.creatorUserID == _user.userID ||
                              (_user.blockUsers != null && _user.blockUsers!.contains(advert.creatorUserID))) {
                            if (index >= viewModel.adverts.length - 5 && viewModel.hasMore && !viewModel.isLoading) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                viewModel.loadMore(_user, _tabController.index);
                              });
                            }
                            return const SizedBox.shrink();
                          }

                          final isLiked = advert.likers.contains(_user.userID);

                          return AdvertCard(
                            advert: advert,
                            isLiked: isLiked,
                            onLikeTap: () async {
                              if (isLiked) {
                                await viewModel.unlikeAdvert(advert.advertID ?? '', _user.userID ?? '');
                              } else {
                                await viewModel.likeAdvert(advert.advertID ?? '', _user.userID ?? '');
                              }
                            },
                          );
                        },
                      ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryColor,
              shape: const StadiumBorder(),
              onPressed: () {
                context.pushNamed(createAdvert);
              },
              label: Text(context.tr('create_listing'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}
