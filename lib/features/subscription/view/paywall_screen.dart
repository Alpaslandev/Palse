import 'package:flutter/material.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/provider/subscription_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? offering;
  bool isLoading = true;
  bool isStarted = false;

  @override
  void initState() {
    super.initState();
    fetchOfferings();
  }

  Future<void> fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      setState(() {
        offering = offerings.current;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Hata durumunda kullanıcıya bildirilebilir
      debugPrint('Offering alınamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : offering == null
                ? const Center(child: Text('Abonelik paketleri yüklenemedi.'))
                : PaywallView(
                    //    offering: offering,
                    displayCloseButton: true,
                    onRestoreCompleted: (CustomerInfo customerInfo) {
                      // Restore tamamlandığında yapılacak işlemler
                      debugPrint('Restore tamamlandı: ${customerInfo.originalAppUserId}');
                    },
                    onDismiss: () {
                      debugPrint('Paywall kapatıldı');
                      // Paywall kapatıldığında yapılacak işlemler
                      Navigator.of(context).pop();
                    },
                    onPurchaseError: (error) {
                      debugPrint('Satın alma hatası: $error');
                    },
                    onPurchaseCompleted: (CustomerInfo customerInfo, StoreTransaction? transaction) {
                      debugPrint('Satın alma tamamlandı: ${customerInfo.originalAppUserId}');
                      subscriptionProvider.updatePremiumStatus(true, authProvider.user?.userID ?? '');
                    },
                    onPurchaseStarted: (Package package) {
                      debugPrint('Satın alma başladı: ${package.identifier}');
                    },
                    onRestoreError: (error) {
                      debugPrint('Geri yükleme hatası: $error');
                    },
                  ),
      ),
    );
  }
}
