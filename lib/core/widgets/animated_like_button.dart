import 'package:flutter/material.dart';

// Twitter/Instagram tarzı animasyonlu like butonu
class AnimatedLikeButton extends StatefulWidget {
  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
    this.size = 20,
    this.fontSize = 11,
  });

  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;
  final double size;
  final double fontSize;

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  bool _previousLikedState = false;
  int _previousLikeCount = 0;

  @override
  void initState() {
    super.initState();
    _previousLikedState = widget.isLiked;
    _previousLikeCount = widget.likeCount;

    // Scale animasyonu - Twitter tarzı bounce efekti
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Renk animasyonu - smooth geçiş
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    // İlk durumu ayarla
    if (widget.isLiked) {
      _colorController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Like durumu değiştiğinde animasyonu tetikle
    if (widget.isLiked != _previousLikedState) {
      _triggerAnimation();
      _previousLikedState = widget.isLiked;
    }

    // Like count değişimini hemen güncelle (senkronize için)
    if (widget.likeCount != _previousLikeCount) {
      _previousLikeCount = widget.likeCount;
    }
  }

  // Like animasyonunu tetikle
  void _triggerAnimation() {
    if (widget.isLiked) {
      // Beğenildi - scale bounce + renk değişimi
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
      _colorController.forward();
    } else {
      // Beğeni kaldırıldı - sadece renk değişimi
      _colorController.reverse();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animasyonlu kalp ikonu
        AnimatedBuilder(
          animation: Listenable.merge([_scaleController, _colorController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(
                widget.isLiked ? Icons.favorite : Icons.favorite_border,
                color: _colorAnimation.value,
                size: widget.size,
              ),
            );
          },
        ),
        // Like sayısı - kalp ile senkronize animasyon
        if (widget.likeCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: AnimatedBuilder(
              animation: _scaleController, // Kalp ile aynı controller
              builder: (context, child) {
                return AnimatedSwitcher(
                  duration:
                      const Duration(milliseconds: 200), // Kalp ile senkron
                  transitionBuilder: (child, animation) {
                    // Çark mantığı: artarken yukarıdan, azalırken aşağıdan
                    final isIncreasing = widget.likeCount > _previousLikeCount;
                    final slideOffset = isIncreasing
                        ? const Offset(0, -0.3) // Hafif hareket
                        : const Offset(0, 0.3); // Hafif hareket

                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: slideOffset,
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut, // Kalp ile aynı curve
                      )),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    widget.likeCount.toString(),
                    key: ValueKey(widget.likeCount),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
