import 'package:flutter/material.dart';
import 'package:palseapp/core/services/subscription_service.dart';
import 'package:palseapp/core/utils/app_theme.dart';
import 'package:palseapp/features/subscription/package_card.dart';
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
  Package? _selectedPackage;
  bool _isFreeTrial = false;
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
          if (packages.isNotEmpty) {
            _selectedPackage = packages.first;
          }
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

  void _selectPackage(Package package) {
    setState(() {
      _selectedPackage = package;
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Özellikler'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
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
                  icon: Icons.check_circle,
                  title: 'İlanınızın Öne Çıkarılması',
                ),
                _PremiumFeatureItem(
                  icon: Icons.check_circle,
                  title: 'Fotoğraf Gönderme Hakkı',
                ),
                _PremiumFeatureItem(
                  icon: Icons.check_circle,
                  title: 'Reklamsız Deneyim',
                ),
                _PremiumFeatureItem(
                  icon: Icons.check_circle,
                  title: 'Profilde Sarı Onay Tiki',
                  isVerified: true,
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
                      final monthlyPrice = _packages.firstWhere((element) => element.packageType == PackageType.monthly).storeProduct.price;

                      return PackageCard(
                        package: package,
                        context: context,
                        subscriptionProvider: subscriptionProvider,
                        onTap: _selectPackage,
                        isSelected: _selectedPackage == package,
                        packageType: package.packageType,
                        monthlyPrice: monthlyPrice,
                      );
                    },
                  ),
          ),

          // Satın alma butonu - Sadece bir paket seçiliyse göster
          if (_selectedPackage != null && !subscriptionProvider.isPremium)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('7 günlük ücretsiz deneme'),
                        Switch(
                            value: _selectedPackage!.packageType == PackageType.sixMonth ? true : false,
                            onChanged: (value) {
                              // TODO: 7 günlük ücretsiz deneme işlemi
                              setState(() {
                                _isFreeTrial = value;
                                _selectedPackage = _packages.firstWhere((element) => element.packageType == PackageType.sixMonth);
                              });
                            }),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _handlePurchase(_selectedPackage!),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      '${_selectedPackage!.storeProduct.priceString} ile Abone Ol',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Satın alımları geri yükle
                      _subscriptionService.restorePurchases();
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Geri Yükle'),
                  ),
                ],
              ),
            ),

          _buildTerms(),
        ],
      ),
    );
  }

  Widget _buildTerms() {
    return SafeArea(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  // TODO: Kullanım koşulları sayfasına yönlendir
                },
                child: const Text(
                  'Kullanım Koşulları',
                  style: TextStyle(decoration: TextDecoration.underline, color: Colors.black),
                ),
              ),
              const Text(' • '),
              TextButton(
                onPressed: () {
                  // TODO: Gizlilik politikası sayfasına yönlendir
                },
                child: const Text(
                  'Gizlilik Politikası',
                  style: TextStyle(decoration: TextDecoration.underline, color: Colors.black),
                ),
              ),
            ],
          ),
          const Text(
            'Aboneliğiniz otomatik olarak yenilenir. İstediğiniz zaman iptal edebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
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
  final bool isVerified;

  const _PremiumFeatureItem({
    required this.icon,
    required this.title,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: isVerified ? Colors.red : Colors.black),
        ),
      ],
    );
  }
}
