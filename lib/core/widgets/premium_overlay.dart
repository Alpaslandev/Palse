import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class PremiumOverlay extends StatelessWidget {
  final Widget child;

  const PremiumOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Selector ile sadece Customer'ın isPremium değerini dinle
    return Selector<AuthProvider, bool>(
      selector: (_, provider) => provider.user?.isPremium ?? false,
      builder: (context, isPremium, _) {
        debugPrint('isPremium: $isPremium');
        // Kullanıcı premium ise doğrudan child widget'ı göster TODO: premium değilse child widget'ı göster
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
      },
    );
  }
}
