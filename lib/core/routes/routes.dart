// Route tanımlamaları
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/widgets/navigation_bar_view.dart';
import 'package:palseapp/features/auth/views/login_view.dart';
import 'package:palseapp/features/home/view/home_view.dart';
import 'package:palseapp/features/profile/view/profile_view.dart';
import 'package:palseapp/features/profile_setup_steps/view/profile_setup_view.dart';
import 'package:palseapp/features/splash/splash_view.dart';

// Route isimleri için sabitler
const String splash = '/';
const String navigationBar = '/navigationBar';
const String home = '/home';
const String login = '/login';
const String profile = '/profile';
const String profileSetup = '/profileSetup';
final List<RouteBase> routes = [
  // Splash screen'i ekleyelim
  GoRoute(
    path: splash,
    builder: (context, state) => const SplashView(),
  ),
  GoRoute(
    path: login,
    name: 'login',
    builder: (context, state) => const LoginView(),
  ),
  GoRoute(
    path: home,
    name: 'home',
    builder: (context, state) => const HomeView(),
  ),
  GoRoute(
    path: navigationBar,
    name: 'navigationBar',
    builder: (context, state) => const NavigationBarView(),
  ),
  GoRoute(
    path: profile,
    name: 'profile',
    builder: (context, state) => const ProfileView(),
  ),
  GoRoute(
    path: profileSetup,
    name: 'profileSetup',
    builder: (context, state) => const ProfileSetupView(),
  ),
];
