import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/routes/routes.dart';

class PremiumOverlay extends StatelessWidget {
  final Widget child;
  final bool isPremium;

  const PremiumOverlay({
    super.key,
    required this.child,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    // Kullanıcı premium ise doğrudan child widget'ı göster
    if (isPremium) {
      return child;
    }

    // Premium değilse, child widget'ın üzerine blur overlay ekle
    return Stack(
      children: [
        // Altta child widget
        child,
        // Üstte blur overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // 3 3
            child: GestureDetector(
              onTap: () => context.pushNamed(paywall),
              child: Container(
                color: Colors.white.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('premium_feature_only'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => context.pushNamed(paywall),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(context.tr('get_premium')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
