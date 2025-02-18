import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/widgets/advert/advert_card.dart';
import 'package:palseapp/features/chats/viewmodel/chats_view_model.dart';
import 'package:palseapp/features/friend_profile/friend_profile_view.dart';
import 'package:palseapp/features/home/viewmodel/home_view_model.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatsViewModel = Provider.of<ChatsViewModel>(context);

    return ChangeNotifierProvider(
      create: (context) => HomeViewModel(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Şehrine Göre'),
                    Tab(text: 'İlgine Göre'),
                    Tab(text: 'Diğer'),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => debugPrint('filter button'),
                icon: const Icon(Icons.tune, color: Colors.blue),
              ),
            ],
          ),
        ),
        body: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            return StreamBuilder<List<Advert>>(
              stream: viewModel.advertsStream,
              builder: (context, advertSnapshot) {
                if (advertSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (advertSnapshot.hasError) {
                  return Center(child: Text('Hata: ${advertSnapshot.error}'));
                }

                if (!advertSnapshot.hasData || advertSnapshot.data!.isEmpty) {
                  return const Center(child: Text('Henüz ilan bulunmuyor'));
                }

                final filteredAdverts = _getFilteredAdverts(
                  advertSnapshot.data!,
                  authProvider.user,
                  _tabController.index,
                );

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredAdverts.length,
                  itemBuilder: (context, index) {
                    final advert = filteredAdverts[index];

                    return StreamBuilder<Customer?>(
                      stream: viewModel.streamCustomer(advert.creatorUserID),
                      builder: (context, customerSnapshot) {
                        if (!customerSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final customer = customerSnapshot.data!;

                        return AdvertCard(
                          advert: advert,
                          customer: customer,
                          isLiked: advert.countUUIDs.contains(authProvider.user?.userID),
                          onLikeTap: () async {
                            final userId = authProvider.user?.userID;
                            if (userId == null) return;

                            if (advert.countUUIDs.contains(userId)) {
                              await viewModel.unlikeAdvert(advert.advertID ?? '', userId);
                            } else {
                              await viewModel.likeAdvert(advert.advertID ?? '', userId);
                            }
                          },
                          onProfileTap: () {
                            context.push(friendProfile, extra: customer);
                          },
                          onMessageTap: () async {
                            final userId = authProvider.user?.userID;
                            if (userId == null) return;

                            final chatId = await chatsViewModel.startOrGetChat(
                              userId,
                              customer.userID ?? '',
                            );

                            if (context.mounted) {
                              context.pushNamed(
                                'messages',
                                extra: {'chatId': chatId, 'otherUserId': customer.userID},
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.blue,
          shape: const StadiumBorder(),
          onPressed: () => context.push(createAdvert),
          label: const Text('İlan Ver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  List<Advert> _getFilteredAdverts(
    List<Advert> adverts,
    Customer? user,
    int tabIndex,
  ) {
    if (user == null) return adverts;

    switch (tabIndex) {
      case 0: // Şehrine Göre
        final userCity = user.city?.toLowerCase().trim();
        if (userCity != null && userCity.isNotEmpty) {
          return adverts.where((advert) => (advert.city?.toLowerCase().trim() ?? '') == userCity).toList();
        }
        return adverts;
      case 1: // İlgine Göre
        final favoriteCategories = user.favoriteCategories?.map((e) => e.toLowerCase().trim()).toList();
        if (favoriteCategories != null && favoriteCategories.isNotEmpty) {
          return adverts.where((advert) => favoriteCategories.contains(advert.advertType.toLowerCase().trim() ?? '')).toList();
        }
        return adverts;

      default: // Diğer
        return adverts;
    }
  }
}
