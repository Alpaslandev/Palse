import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/advert_card.dart';
import 'package:palseapp/features/chats/viewmodel/chats_view_model.dart';
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
    final chatsViewModel = Provider.of<ChatsViewModel>(context);

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
                      tabs: const [
                        Tab(text: 'Şehrine Göre', iconMargin: EdgeInsets.zero),
                        Tab(text: 'İlgine Göre', iconMargin: EdgeInsets.zero),
                        Tab(text: 'Diğer', iconMargin: EdgeInsets.zero),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.push(filter);
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
                    ? const Center(child: Text('Henüz ilan bulunmuyor'))
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

                              if (!viewModel.hasMore && _tabController.index != 2) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Bu kategoride başka ilan bulunmamaktadır.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () {
                                              _tabController.animateTo(2);
                                            },
                                            child: const Text(
                                              'Diğer ilanları görmek için tıklayın',
                                              style: TextStyle(
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
                              // onProfileTap: () => context.push(friendProfile, extra: customer),
                              // onMessageTap: () async {
                              //   final userId = authProvider.user?.userID;
                              //   if (userId == null) return;

                              //   final chatId = await chatsViewModel.startOrGetChat(
                              //     userId,
                              //     customer.userID ?? '',
                              //   );

                              //   if (context.mounted) {
                              //     context.push('/chats/$chatId?otherId=${customer.userID}&currentId=$userId');
                              //   }
                              // },
                            );
                          },
                        ),
                      ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryColor,
              shape: const StadiumBorder(),
              onPressed: () => context.push(createAdvert),
              label: const Text('İlan Ver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}
