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
      create: (context) => HomeViewModel()..getAdverts(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  dividerHeight: 0.2,
                  isScrollable: false,
                  tabs: const [
                    Tab(text: 'İlgine Göre'),
                    Tab(text: 'Şehrine Göre'),
                    Tab(text: 'Diğer'),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  debugPrint('filter button');
                },
                icon: const Icon(Icons.tune, color: Colors.blue),
              ),
            ],
          ),
        ),
        body: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filtrelenmiş ve sıralanmış listeler
            final filteredAdverts = _getFilteredAdverts(
              viewModel.adverts,
              authProvider.user,
              _tabController.index,
            );

            return ListView.builder(
              shrinkWrap: true,
              itemCount: filteredAdverts.length,
              itemBuilder: (context, index) {
                final advert = filteredAdverts[index];
                final customer = viewModel.getCustomerForAdvert(advert);

                if (customer == null) return const SizedBox.shrink();

                return AdvertCard(
                  advert: advert,
                  customer: customer,
                  onProfileTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FriendProfileView(customer: customer),
                      ),
                    );
                  },
                  onMessageTap: () async {
                    final chatId = await chatsViewModel.startOrGetChat(
                      authProvider.user!.userID ?? '',
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
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.blue,
          shape: const StadiumBorder(),
          onPressed: () {
            debugPrint('floating action button');
            context.push(createAdvert);
          },
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
      case 0: // İlgine Göre
        final favoriteCategories = user.favoriteCategories?.map((e) => e.toLowerCase().trim()).toList();
        if (favoriteCategories != null && favoriteCategories.isNotEmpty) {
          return adverts.where((advert) => favoriteCategories.contains(advert.advertType?.toLowerCase().trim() ?? '')).toList();
        }
        return adverts;

      case 1: // Şehrine Göre
        final userCity = user.city?.toLowerCase().trim();
        if (userCity != null && userCity.isNotEmpty) {
          return adverts.where((advert) => (advert.city?.toLowerCase().trim() ?? '') == userCity).toList();
        }
        return adverts;

      default: // Diğer
        return adverts;
    }
  }
}
