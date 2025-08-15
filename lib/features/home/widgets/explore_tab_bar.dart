import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/utils/app_theme.dart';

// HomeView'daki Keşfet sekmesi için özel tasarlanmış TabBar widget'ı.
class ExploreTabBar extends StatefulWidget {
  final TabController controller;

  const ExploreTabBar({super.key, required this.controller});

  @override
  State<ExploreTabBar> createState() => _ExploreTabBarState();
}

class _ExploreTabBarState extends State<ExploreTabBar> {
  @override
  void initState() {
    super.initState();
    // Tab seçim değişikliklerini dinleyerek UI'ı günceller.
    widget.controller.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTabSelection);
    super.dispose();
  }

  // Tab seçimi değiştiğinde setState çağırarak widget'ın yeniden çizilmesini sağlar.
  void _handleTabSelection() {
    if (mounted && widget.controller.indexIsChanging) {
      setState(() {});
    }
  }

  // Seçili duruma göre tab widget'ı oluşturan yardımcı method.
  Widget _buildTab(String text, int index) {
    final isSelected = widget.controller.index == index;

    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: SizedBox(
        height: 40,
        child: TabBar(
          controller: widget.controller,
          // Özel stil için varsayılan indicator'ı kaldır.
          indicator: const BoxDecoration(),
          dividerColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: [
            _buildTab(context.tr('city_based'), 0),
            _buildTab(context.tr('interest_based'), 1),
            _buildTab(context.tr('other'), 2),
          ],
        ),
      ),
    );
  }
}
