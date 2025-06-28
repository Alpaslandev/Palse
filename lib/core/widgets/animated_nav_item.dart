import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vibration/vibration.dart';
import 'package:palseapp/core/utils/app_theme.dart';

// Nav bar item'ı için animasyonlu widget
class AnimatedNavItem extends StatefulWidget {
  const AnimatedNavItem({
    super.key,
    required this.index,
    required this.iconPath,
    required this.iconSize,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final String iconPath;
  final double iconSize;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<AnimatedNavItem> createState() => AnimatedNavItemState();
}

class AnimatedNavItemState extends State<AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _iconSizeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Daha kısa ve yumuşak
      vsync: this,
    );

    // Scale animasyonu - SMOOTH ve CONTINUOUS
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1, // Daha az scale
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Daha yumuşak curve
    ));

    // Renk animasyonu - GRADIENT geçiş
    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: Colors.white,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Daha yumuşak renk geçişi
    ));

    // Icon boyut animasyonu - FLUID büyüme
    _iconSizeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2, // Daha az büyüme
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Overshoot kaldırıldı
    ));

    // Glow animasyonu - PROGRESSIVE parlaklık
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Daha yumuşak glow
    ));

    // İlk durumu ayarla
    if (widget.isSelected) {
      _animationController.value = 1.0;
    }
  }

  // Dışarıdan çağrılabilir animasyon metodları
  void animateToSelected() {
    _animationController.forward();
    _triggerHapticFeedback();
  }

  void animateToUnselected() {
    _animationController.reverse();
  }

  @override
  void didUpdateWidget(AnimatedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Artık dışarıdan kontrol edileceği için bu kısım pasif
    // Senkronize animasyon için LandingView kontrolü yapacak
  }

  // Titreşim efekti
  Future<void> _triggerHapticFeedback() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Çok hafif titreşim (5ms) - minimal güç
        Vibration.vibrate(duration: 5);
      }
    } catch (e) {
      // Titreşim desteklenmiyorsa sessizce devam et
      debugPrint('Titreşim desteklenmiyor: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected
                    ? AppTheme.primaryColor
                    : Colors.transparent,
                border: Border.all(
                  color: widget.isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(
                      0.3 * _glowAnimation.value,
                    ),
                    blurRadius: 8 * _glowAnimation.value,
                    spreadRadius: 2 * _glowAnimation.value,
                  ),
                ],
              ),
              child: Center(
                child: Transform.scale(
                  scale: _iconSizeAnimation.value,
                  child: SvgPicture.asset(
                    widget.iconPath,
                    width: widget.iconSize,
                    height: widget.iconSize,
                    colorFilter: ColorFilter.mode(
                      _colorAnimation.value ?? Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
