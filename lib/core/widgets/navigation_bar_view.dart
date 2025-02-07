import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:palseapp/core/widgets/project_app_bar.dart';
import 'package:palseapp/features/favorites/view/favorites_view.dart';
import 'package:palseapp/features/home/view/home_view.dart';
import 'package:palseapp/features/my_advert/view/my_advert_view.dart';
import 'package:palseapp/features/profile/view/profile_view.dart';

class NavigationBarView extends StatefulWidget {
  const NavigationBarView({super.key});

  @override
  State<NavigationBarView> createState() => _NavigationBarViewState();
}

class _NavigationBarViewState extends State<NavigationBarView> {
  int _selectedIndex = 0;

  // Gösterilecek sayfalar
  final List<Widget> _pages = [
    const HomeView(),
    const MyAdvertView(),
    const FavoritesView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ProjectAppBar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        indicatorColor: Colors.blue,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: SvgPicture.asset('assets/vectors/home_1_x2.svg'),
            selectedIcon: SvgPicture.asset('assets/vectors/vector1bar.svg'),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: SvgPicture.asset('assets/vectors/ad_1_x2.svg'),
            selectedIcon: SvgPicture.asset('assets/vectors/vector3bar.svg'),
            label: 'İlanlarım',
          ),
          NavigationDestination(
            icon: SvgPicture.asset('assets/vectors/vector_5_x2.svg'),
            selectedIcon: SvgPicture.asset('assets/vectors/vector4bar.svg'),
            label: 'Favoriler',
          ),
          NavigationDestination(
            icon: SvgPicture.asset('assets/vectors/vector_5_x2.svg'),
            selectedIcon: SvgPicture.asset('assets/vectors/vector4bar.svg'),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
