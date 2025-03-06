import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isSignUp = false;
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
            Text(
              context.tr('welcome_message'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            if (!_isSignUp) ...[
              // Email TextField
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: context.tr('email'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password TextField
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: context.tr('password'),
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
            ] else ...[
              // Email TextField
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: context.tr('email'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password TextField
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: context.tr('password'),
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
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: context.tr('confirm_password'),
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
            ],
            const SizedBox(height: 24),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_isSignUp) {
                    authProvider.signUpWithEmailAndPassword(_emailController.text, _passwordController.text);
                  } else {
                    authProvider.loginWithEmail(_emailController.text, _passwordController.text);
                  }
                  //    Navigator.push(context, MaterialPageRoute(builder: (context) => NicknameStep(controller: _emailController)));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(_isSignUp ? context.tr('register') : context.tr('login')),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(context.tr('or')),
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
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('login_successful'))),
                            );
                          } catch (e) {
                            // Hata yönetimi
                            debugPrint('Giriş hatası: $e');
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('login_failed') + ': $e')),
                            );
                          }
                        },
                ),
              ],
            ),

            Text(context.tr('privacy_terms_agreement'))
          ],
        ),
      ),
    );
  }
}
