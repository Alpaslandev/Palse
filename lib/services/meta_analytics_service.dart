import 'package:flutter_meta_sdk/flutter_meta_sdk.dart';

class MetaAnalyticsService {
  // Meta SDK instance
  final FlutterMetaSdk _metaSdk = FlutterMetaSdk();

  // Singleton pattern
  static final MetaAnalyticsService _instance = MetaAnalyticsService._internal();
  factory MetaAnalyticsService() => _instance;
  MetaAnalyticsService._internal();

  // Olay izleme
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    try {
      await _metaSdk.logEvent(
        name: eventName,
        parameters: parameters,
      );
    } catch (e) {
      print("Meta olay izleme hatası: $e");
    }
  }

  // Uygulama başlatma olayını izleme
  Future<void> logAppLaunch() async {
    try {
      await _metaSdk.logEvent(
        name: 'app_launch',
        parameters: {
          'platform': 'flutter',
        },
      );
    } catch (e) {
      print("Meta uygulama başlatma izleme hatası: $e");
    }
  }

  // Satın alma olayı izleme
  Future<void> logPurchase({
    required double amount,
    required String currency,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _metaSdk.logPurchase(
        amount: amount,
        currency: currency,
        parameters: parameters,
      );
    } catch (e) {
      print("Meta satın alma izleme hatası: $e");
    }
  }
}
