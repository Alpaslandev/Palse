import 'package:flutter/material.dart';
import 'package:palseapp/features/home/view/home_view.dart';
import 'package:palseapp/features/story/view/storys_view.dart';

class GlobalKeys {
  // Singleton pattern
  GlobalKeys._();
  static final GlobalKeys instance = GlobalKeys._();

  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final navigatorKey = GlobalKey<NavigatorState>();
  final homeViewKey = GlobalKey<HomeViewState>();
  final storysViewKey = GlobalKey<StorysViewState>();
}
