import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:palseapp/core/services/notification_service.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/chats/viewmodel/chats_view_model.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:palseapp/core/provider/subscription_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i güvenli şekilde başlat
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      // Zaten başlatılmış, görmezden gel
      debugPrint('Firebase already initialized');
    } else {
      // Başka bir hata varsa fırlat
      rethrow;
    }
  }

  // RevenueCat'i başlat
  if (Platform.isIOS) {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration('appl_nqgFBnNbiUeCvilAmLqKsvbZNal'));
  } else if (Platform.isAndroid) {
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration('goog_PEygpHUWqHBCeYbZdjULShUAQfz'));
  }

  final authProvider = AuthProvider();
  await authProvider.initializeAuth();

  final notificationService = NotificationService();
  await notificationService.initialize();

  AppRouter.initialize(authProvider);
  // Cihazın diline uygun tarih formatlamasını başlat
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  debugPrint('Locale: $locale');
  await initializeDateFormatting(locale.toString(), null);
  Intl.defaultLocale = locale.toString();
  debugPrint('Intl.defaultLocale: ${Intl.defaultLocale}');
  final subscriptionProvider = SubscriptionProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: subscriptionProvider),
        ChangeNotifierProvider(create: (_) => ChatsViewModel(authProvider.user!)),
      ],
      child: MyApp(notificationService: notificationService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Palse App',
      theme: AppTheme.theme,
      routerConfig: AppRouter.router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      builder: (context, child) {
        // Router hazır olduğunda context'i set et
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notificationService.setContext(context);
        });
        return child!;
      },
    );
  }
}
