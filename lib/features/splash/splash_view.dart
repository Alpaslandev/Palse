// Splash ekranı
import 'package:flutter/material.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Initialize edilmediyse veya loading durumundaysa loading göster
            if (authProvider.isLoading) {
              return const CircularProgressIndicator();
            }

            // Router yönlendirmeyi otomatik yapacak
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
