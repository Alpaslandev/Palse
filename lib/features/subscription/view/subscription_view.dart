// Abonelik ekranı - Bottom sheet olarak açılıyor
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/services/subscription_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:palseapp/core/provider/subscription_provider.dart';
import 'package:provider/provider.dart';

class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  final _subscriptionService = SubscriptionService();
  List<Package> _packages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    if (!mounted) return;

    try {
      final packages = await _subscriptionService.getPackages();
      if (mounted) {
        setState(() {
          _packages = packages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paketler yüklenirken bir hata oluştu')),
        );
      }
    }
  }

  Future<void> _handlePurchase(Package package) async {
    try {
      await _subscriptionService.purchasePackage(package);
      if (mounted) {
        Navigator.of(context).pop(); // Başarılı satın alma sonrası kapat
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Satın alma işlemi başarısız oldu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst kısım - Başlık ve kapatma butonu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Premium Özellikler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Premium özelliklerin listesi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              spacing: 4,
              children: const [
                _PremiumFeatureItem(
                  icon: Icons.remove_red_eye,
                  title: 'Profiline Bakanları Gör',
                ),
                _PremiumFeatureItem(
                  icon: Icons.remove_red_eye,
                  title: 'İlanını Beğenenleri Gör',
                ),
                _PremiumFeatureItem(
                  icon: Icons.favorite,
                  title: 'Sınırsız Beğeni',
                ),
                _PremiumFeatureItem(
                  icon: Icons.photo,
                  title: 'Fotoğraf Gönderme Hakkı',
                ),
                _PremiumFeatureItem(
                  icon: Icons.check_circle,
                  title: 'Reklamsız Deneyim',
                ),
                _PremiumFeatureItem(
                  icon: Icons.verified,
                  title: 'Profilde Sarı Onay Tiki',
                ),
              ],
            ),
          ),

          // Paketler
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _packages.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final package = _packages[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(
                            package.storeProduct.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(package.storeProduct.description),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                package.storeProduct.priceString,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          enabled: !subscriptionProvider.isPremium,
                          onTap: () => _handlePurchase(package),
                        ),
                      );
                    },
                  ),
          ),

          // Terms & Conditions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Aboneliğiniz otomatik olarak yenilenir. İstediğiniz zaman iptal edebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: Kullanım koşulları sayfasına yönlendir
                      },
                      child: const Text('Kullanım Koşulları'),
                    ),
                    const Text(' • '),
                    TextButton(
                      onPressed: () {
                        // TODO: Gizlilik politikası sayfasına yönlendir
                      },
                      child: const Text('Gizlilik Politikası'),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Bottom padding for safe area
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Premium özellik item widget'ı
class _PremiumFeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _PremiumFeatureItem({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
