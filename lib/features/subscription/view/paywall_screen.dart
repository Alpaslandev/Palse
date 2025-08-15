import 'package:flutter/material.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/provider/subscription_provider.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? offering;
  bool isLoading = true;
  bool isStarted = false;
  final facebookAppEvents = FacebookAppEvents();
  Package? _startedPackage;

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
                      debugPrint(
                          'Restore tamamlandı: ${customerInfo.originalAppUserId}');
                    },
                    onDismiss: () {
                      debugPrint('Paywall kapatıldı');
                      // Paywall kapatıldığında yapılacak işlemler
                      Navigator.of(context).pop();
                    },
                    onPurchaseError: (error) {
                      debugPrint('Satın alma hatası: $error');
                    },
                    onPurchaseCompleted: (CustomerInfo customerInfo,
                        StoreTransaction? transaction) {
                      debugPrint(
                          'Satın alma tamamlandı: ${customerInfo.originalAppUserId}');
                      subscriptionProvider.updatePremiumStatus(
                          true, authProvider.user?.userID ?? '');

                      // Meta (Facebook) Purchase event loglama
                      try {
                        final amount = _startedPackage?.storeProduct.price;
                        final currency =
                            _startedPackage?.storeProduct.currencyCode;

                        if (amount != null && currency != null) {
                          facebookAppEvents.logPurchase(
                            amount: amount,
                            currency: currency,
                            parameters: {
                              'product_id':
                                  _startedPackage?.storeProduct.identifier,
                              'transaction_id':
                                  transaction?.transactionIdentifier,
                              'subscription': true,
                              'period': _startedPackage?.packageType.toString(),
                              'product_name':
                                  _startedPackage?.storeProduct.title,
                              'product_description':
                                  _startedPackage?.storeProduct.description,
                              'product_price':
                                  _startedPackage?.storeProduct.price,
                              'product_currency':
                                  _startedPackage?.storeProduct.currencyCode,

                              // İstersen ek alanlar: 'subscription': true, 'period': 'P1M' vb.
                            },
                          );
                          debugPrint(
                              'Facebook Purchase event gönderildi: $amount $currency');
                        } else {
                          debugPrint(
                              'Facebook Purchase event atlandı: amount/currency yok');
                        }
                      } catch (e) {
                        debugPrint('Facebook Purchase event hata: $e');
                      } finally {
                        _startedPackage =
                            null; // sonraki alışveriş için temizle
                      }
                    },
                    onPurchaseStarted: (Package package) {
                      _startedPackage = package;
                      // Meta (Facebook) InitiateCheckout event loglama
                      try {
                        facebookAppEvents.logInitiatedCheckout(
                          totalPrice: package.storeProduct.price,
                          currency: package.storeProduct.currencyCode,
                          contentType: "subscription",
                          contentId: package.storeProduct.identifier,
                          numItems: 1,
                          paymentInfoAvailable: true,
                        );
                        debugPrint(
                            'Facebook InitiateCheckout event gönderildi');
                      } catch (e) {
                        debugPrint('Facebook InitiateCheckout event hata: $e');
                      }
                      debugPrint('Satın alma başladı: ${package.identifier}');
                    },
                    onRestoreError: (error) {
                      debugPrint('Geri yükleme hatası: $error');
                      facebookAppEvents.logEvent(
                        name: "PurchaseFailed",
                        parameters: {
                          "product_id":
                              _startedPackage?.storeProduct.identifier,
                          "error_code": error.code,
                          "error_message": error.message
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
