import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:palseapp/core/routes/app_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/firebase_options.dart';
import 'package:palseapp/features/chats/viewmodel/chats_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authProvider = AuthProvider();
  await authProvider.initializeAuth();
  AppRouter.initialize(authProvider);
  // Cihazın diline uygun tarih formatlamasını başlat
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  await initializeDateFormatting(locale.toString(), null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ChatsViewModel(authProvider)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
    );
  }
}
