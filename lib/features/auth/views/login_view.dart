import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/features/profile_setup_steps/steps/nickname_step.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header
            const Text(
              "Tekrar, Hoş geldin 👋",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Email TextField
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'E-posta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Password TextField
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: 'Şifre',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => NicknameStep()));
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Giriş Yap'),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Veya'),
            const SizedBox(height: 16),

            // Social Login Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: SvgPicture.asset('assets/vectors/google.svg', width: 24),
                  onPressed: () async {
                    await authProvider.loginWithGoogle();
                    if (!context.mounted) return;
                    // context.go(profileSetup);
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: authProvider.isLoading ? const CircularProgressIndicator() : SvgPicture.asset('assets/vectors/apple.svg', width: 24),
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          try {
                            await authProvider.loginWithGoogle();
                            // Router otomatik olarak yönlendirecek
                          } catch (e) {
                            // Hata yönetimi
                            debugPrint('Giriş hatası: $e');
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Giriş başarısız: $e')),
                            );
                          }
                        },
                ),
              ],
            ),

            Text("Giriş yaparak Gizlilik Politikasını ve Kullanım Koşullarını kabul etmiş sayılırsınız.")
          ],
        ),
      ),
    );
  }
}
