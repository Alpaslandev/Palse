import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/advert_card.dart';
import 'package:palseapp/features/home/viewmodel/home_view_model.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late TabController _tabController;
  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _viewModel = HomeViewModel();
    _tabController.addListener(_onTabChanged);

    // İlk yüklemeyi yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _viewModel.fetchAdvertsForTab(authProvider.user, 0);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final authProvider = context.read<AuthProvider>();
      _viewModel.fetchAdvertsForTab(authProvider.user, _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                            if (viewModel.hasMore && !viewModel.isLoading) {
                              debugPrint('Listenin sonuna gelindi, yeni ilanlar yükleniyor...');
                              viewModel.loadMore(authProvider.user, _tabController.index);
                            }
                          }
                          return true;
                        },
                        child: ListView.builder(
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

                            return AdvertCard(
                              advert: advert,
                              isLiked: advert.likers.contains(authProvider.user?.userID),
                              onLikeTap: () async {
                                final userId = authProvider.user?.userID;
                                if (userId == null) return;

                                if (advert.likers.contains(userId)) {
                                  await viewModel.unlikeAdvert(advert.advertID ?? '', userId);
                                } else {
                                  await viewModel.likeAdvert(advert.advertID ?? '', userId);
                                }
                              },
                            );
                          },
                        ),
                      ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryColor,
              shape: const StadiumBorder(),
              onPressed: () {
                // SVG önizleme dialogunu göster
                _showSvgPreviewDialog(context);
              },
              label: Text(context.tr('create_listing'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }

  // SVG önizleme dialogu
  void _showSvgPreviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'SVG Dosyaları Önizleme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    children: [
                      _buildSvgItem(context, 'vector_star_empty.svg'),
                      _buildSvgItem(context, 'vector_x2.svg'),
                      _buildSvgItem(context, 'vectormessage.svg'),
                      _buildSvgItem(context, 'vector_6_x2.svg'),
                      _buildSvgItem(context, 'vector_7_x2.svg'),
                      _buildSvgItem(context, 'vector_8_x2.svg'),
                      _buildSvgItem(context, 'vector_9_x2.svg'),
                      _buildSvgItem(context, 'vector_confirm.svg'),
                      _buildSvgItem(context, 'vector_profile_confirm.svg'),
                      _buildSvgItem(context, 'vector_2_x2.svg'),
                      _buildSvgItem(context, 'vector_3_x2.svg'),
                      _buildSvgItem(context, 'vector_4_x2.svg'),
                      _buildSvgItem(context, 'vector_5_x2.svg'),
                      _buildSvgItem(context, 'vector_5_x231.svg'),
                      _buildSvgItem(context, 'vector4bar.svg'),
                      _buildSvgItem(context, 'vector_10_x2.svg'),
                      _buildSvgItem(context, 'vector_11_x2.svg'),
                      _buildSvgItem(context, 'vector_1_x2.svg'),
                      _buildSvgItem(context, 'vector3.0.svg'),
                      _buildSvgItem(context, 'vector3bar.svg'),
                      _buildSvgItem(context, 'vector1bar.svg'),
                      _buildSvgItem(context, 'vector2.0.svg'),
                      _buildSvgItem(context, 'stroke_1_x222.svg'),
                      _buildSvgItem(context, 'profile.svg'),
                      _buildSvgItem(context, 'vector1.0.svg'),
                      _buildSvgItem(context, 'star_filled_2.svg'),
                      _buildSvgItem(context, 'star_mini1.svg'),
                      _buildSvgItem(context, 'star_mini_22.svg'),
                      _buildSvgItem(context, 'stroke_11_x2.svg'),
                      _buildSvgItem(context, 'stroke_1_x2.svg'),
                      _buildSvgItem(context, 'show_hide_1_x2.svg'),
                      _buildSvgItem(context, 'star_filled_1.svg'),
                      _buildSvgItem(context, 'ringing_iconly_pro_1_x2.svg'),
                      _buildSvgItem(context, 'ringtone_iconly_pro_1_x2.svg'),
                      _buildSvgItem(context, 'search_iconly_pro_x2.svg'),
                      _buildSvgItem(context, 'setting_iconly_pro_x2.svg'),
                      _buildSvgItem(context, 'plus_4_iconly_pro_1_x2.svg'),
                      _buildSvgItem(context, 'plus_yeni_ilan.svg'),
                      _buildSvgItem(context, 'logout_iconly_pro_x2.svg'),
                      _buildSvgItem(context, 'image_x2.svg'),
                      _buildSvgItem(context, 'gem_iconly_pro_x2.svg'),
                      _buildSvgItem(context, 'google.svg'),
                      _buildSvgItem(context, 'home_1_x2.svg'),
                      _buildSvgItem(context, 'docuemnt_2_lines_iconly_pro_x2.svg'),
                      _buildSvgItem(context, 'edit_x2.svg'),
                      _buildSvgItem(context, 'eye_iconly_pro_4_x2.svg'),
                      _buildSvgItem(context, 'filter_x2.svg'),
                      _buildSvgItem(context, 'ad_1_x2.svg'),
                      _buildSvgItem(context, 'apple.svg'),
                      _buildSvgItem(context, 'category_1_x2.svg'),
                      _buildSvgItem(context, 'chat_iconly_pro_x2.svg'),
                      _buildSvgItem(context, 'counter_clockwise_undo_iconly_pro_x2.svg'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Orijinal işlevi çağır
                    context.pushNamed(createAdvert);
                  },
                  child: Text('İlan Oluştur'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // SVG öğesi widget'ı
  Widget _buildSvgItem(BuildContext context, String fileName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SvgPicture.asset(
                'assets/vectors/$fileName',
                width: 48,
                height: 48,
                colorFilter: const ColorFilter.mode(AppTheme.primaryColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fileName,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
