import 'package:flutter/material.dart';

class GlobalKeys {
  // Singleton pattern
  GlobalKeys._();
  static final GlobalKeys instance = GlobalKeys._();

  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final navigatorKey = GlobalKey<NavigatorState>();
}
