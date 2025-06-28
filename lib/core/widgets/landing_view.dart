import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/keys/global_keys.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/animated_nav_item.dart';
import 'package:palseapp/core/widgets/project_app_bar.dart';

class LandingView extends StatefulWidget {
  const LandingView({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView>
    with TickerProviderStateMixin {
  // Master animasyon controller'ı - tüm nav item'ları koordine eder
  late AnimationController _masterAnimationController;
  late List<GlobalKey<AnimatedNavItemState>> _navItemKeys;

  @override
  void initState() {
    super.initState();

    // Master controller - tüm animasyonları senkronize eder
    _masterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Her nav item için anahtar oluştur
    _navItemKeys =
        List.generate(4, (index) => GlobalKey<AnimatedNavItemState>());
  }

  @override
  void didUpdateWidget(LandingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      _triggerSynchronizedAnimation();
    }
  }

  // Senkronize animasyon tetikleyici
  void _triggerSynchronizedAnimation() {
    final selectedIndex = widget.navigationShell.currentIndex;

    // Tüm nav item'lara aynı anda animasyon komutunu gönder
    for (int i = 0; i < _navItemKeys.length; i++) {
      final navItemState = _navItemKeys[i].currentState;
      if (navItemState != null) {
        if (i == selectedIndex) {
          navItemState.animateToSelected();
        } else {
          navItemState.animateToUnselected();
        }
      }
    }
  }

  @override
  void dispose() {
    _masterAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(BuildContext context, int index) {
    // Mevcut tab'a tekrar tıklandıysa ve bu anasayfa ise yenile
    if (widget.navigationShell.currentIndex == index) {
      if (index == 0) {
        GlobalKeys.instance.homeViewKey.currentState?.refreshFromNavigation();
      }
    } else {
      // Değilse, o dala geçiş yap
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
    }
  }

  // İkon boyutunu hesaplayan yardımcı metod
  double _getIconSize(double navBarHeight) {
    return navBarHeight * 0.35;
  }

  // NavigationBar yüksekliğini hesaplayan yardımcı metod
  double _getNavBarHeight(BuildContext context) {
    return (MediaQuery.of(context).size.height * 0.07).clamp(56.0, 65.0);
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = _getNavBarHeight(context);
    final iconSize = _getIconSize(navBarHeight);
    final selectedIndex = widget.navigationShell.currentIndex;

    // Home sayfasında mı kontrol et
    final isHomePage = selectedIndex == 0;

    return Scaffold(
      appBar: const ProjectAppBar(),
      body: widget.navigationShell,
      floatingActionButton: isHomePage
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primaryColor,
              shape: const StadiumBorder(),
              onPressed: () {
                context.pushNamed(createAdvert);
              },
              label: Text(
                context.tr('create_listing'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: navBarHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedNavItem(
                key: _navItemKeys[0],
                index: 0,
                iconPath: 'assets/navbar_ic/home_1_x2.svg',
                iconSize: iconSize,
                isSelected: selectedIndex == 0,
                onTap: () => _onItemTapped(context, 0),
              ),
              AnimatedNavItem(
                key: _navItemKeys[1],
                index: 1,
                iconPath: 'assets/navbar_ic/category_1_x2.svg',
                iconSize: iconSize,
                isSelected: selectedIndex == 1,
                onTap: () => _onItemTapped(context, 1),
              ),
              AnimatedNavItem(
                key: _navItemKeys[2],
                index: 2,
                iconPath: 'assets/navbar_ic/ad_1_x2.svg',
                iconSize: iconSize,
                isSelected: selectedIndex == 2,
                onTap: () => _onItemTapped(context, 2),
              ),
              AnimatedNavItem(
                key: _navItemKeys[3],
                index: 3,
                iconPath: 'assets/navbar_ic/profile.svg',
                iconSize: iconSize,
                isSelected: selectedIndex == 3,
                onTap: () => _onItemTapped(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
