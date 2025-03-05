import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/core/widgets/project_app_bar.dart';

class LandingView extends StatefulWidget {
  const LandingView({super.key, required this.child});
  final Widget child;

  @override
  State<LandingView> createState() => _LandingViewState();
}

class _LandingViewState extends State<LandingView> {
  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(home)) return 0;
    if (location.startsWith(categories)) return 1;
    if (location.startsWith(myAdverts)) return 2;
    if (location.startsWith(profile)) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.goNamed(home);
        break;
      case 1:
        context.go(categories);
        break;
      case 2:
        context.go(myAdverts);
        break;
      case 3:
        context.go(profile);
        break;
    }
  }

  // İkon boyutunu hesaplayan yardımcı metod
  double _getIconSize(double navBarHeight) {
    // NavigationBar yüksekliğinin %60'ı kadar bir boyut
    return navBarHeight * 0.4;
  }

  // NavigationBar yüksekliğini hesaplayan yardımcı metod
  double _getNavBarHeight(BuildContext context) {
    // Ekran yüksekliğinin %7'i kadar (minimum 56, maksimum 65 piksel)
    return (MediaQuery.of(context).size.height * 0.07).clamp(56.0, 65.0);
  }

  @override
  Widget build(BuildContext context) {
    final navBarHeight = _getNavBarHeight(context);
    final iconSize = _getIconSize(navBarHeight);
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      appBar: const ProjectAppBar(),
      body: widget.child,
      bottomNavigationBar: SafeArea(
        child: Container(
          height: navBarHeight,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(context, 0, 'assets/vectors/home_1_x2.svg', iconSize, selectedIndex),
              _buildNavItem(context, 1, 'assets/vectors/category_1_x2.svg', iconSize, selectedIndex),
              _buildNavItem(context, 2, 'assets/vectors/ad_1_x2.svg', iconSize, selectedIndex),
              _buildNavItem(context, 3, 'assets/vectors/vector_5_x2.svg', iconSize, selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String iconPath, double iconSize, int selectedIndex) {
    final isSelected = selectedIndex == index;
    final Color svgColor = isSelected ? Colors.white : Colors.grey;
    final double currentIconSize = isSelected ? iconSize * 1.4 : iconSize;

    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            width: currentIconSize,
            height: currentIconSize,
            colorFilter: ColorFilter.mode(svgColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
