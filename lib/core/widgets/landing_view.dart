import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/routes/routes.dart';
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
    if (location.startsWith(myAdverts)) return 1;
    if (location.startsWith(messages)) return 2;
    if (location.startsWith(profile)) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(home);
        break;
      case 1:
        context.go(myAdverts);
        break;
      case 2:
        context.go(chats);
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
              _buildNavItem(context, 0, 'assets/vectors/home_1_x2.svg', 'assets/vectors/vector1bar.svg', iconSize, selectedIndex),
              _buildNavItem(context, 1, 'assets/vectors/ad_1_x2.svg', 'assets/vectors/vector3bar.svg', iconSize, selectedIndex),
              _buildNavItem(context, 2, 'assets/vectors/vector_5_x2.svg', 'assets/vectors/vector4bar.svg', iconSize, selectedIndex),
              _buildNavItem(context, 3, 'assets/vectors/vector_5_x2.svg', 'assets/vectors/vector4bar.svg', iconSize, selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, String iconPath, String selectedIconPath, double iconSize, int selectedIndex) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.blue : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Center(
          child: SvgPicture.asset(
            isSelected ? selectedIconPath : iconPath,
            width: iconSize,
            height: iconSize,
          ),
        ),
      ),
    );
  }
}
