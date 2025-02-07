import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/provider/auth_provider.dart';

// Kullanıcının auth durumuna göre sayfa yönlendirmesi yapan wrapper widget
class AuthWrapper extends StatelessWidget {
  final Widget authenticatedRoute;
  final Widget unauthenticatedRoute;

  const AuthWrapper({
    super.key,
    required this.authenticatedRoute,
    required this.unauthenticatedRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Yükleme durumunda loading göster
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Auth durumuna göre yönlendirme yap
        return authProvider.isAuthenticated ? authenticatedRoute : unauthenticatedRoute;
      },
    );
  }
}
