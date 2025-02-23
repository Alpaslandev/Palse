import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:palseapp/core/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/firebase_options.dart';
import 'package:palseapp/features/chats/viewmodel/chats_view_model.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:palseapp/core/provider/subscription_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
  await initializeDateFormatting(locale.toString(), null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => ChatsViewModel(authProvider)),
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
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        tabBarTheme: TabBarTheme(
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          dividerHeight: 0.2,
        ),
      ),
      routerConfig: AppRouter.router,
      builder: (context, child) {
        notificationService.setContext(context);
        return child!;
      },
    );
  }
}
