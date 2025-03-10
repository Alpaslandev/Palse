import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:palseapp/core/provider/ads_provider.dart';

class AdsDemoPage extends StatelessWidget {
  const AdsDemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // AdsProvider'a erişim
    final adsProvider = Provider.of<AdsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reklam Testi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Geçiş reklamı durumu
            Text(
              'Geçiş Reklamı Hazır: ${adsProvider.isInterstitialAdReady ? 'Evet' : 'Hayır'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Ödüllü reklam durumu
            Text(
              'Ödüllü Reklam Hazır: ${adsProvider.isRewardedAdReady ? 'Evet' : 'Hayır'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Geçiş reklamı gösterme butonu
            ElevatedButton(
              onPressed: () async {
                // Geçiş reklamını göster
                final shown = await adsProvider.showInterstitialAd();
                if (!shown && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geçiş reklamı henüz hazır değil, lütfen daha sonra tekrar deneyin.'),
                    ),
                  );
                }
              },
              child: const Text('Geçiş Reklamı Göster'),
            ),
            const SizedBox(height: 20),

            // Ödüllü reklam gösterme butonu
            ElevatedButton(
              onPressed: () async {
                // Ödüllü reklamı göster
                final shown = await adsProvider.showRewardedAd(
                  onRewarded: (amount) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tebrikler! $amount ödül kazandınız!'),
                        ),
                      );
                    }
                  },
                );

                if (!shown && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ödüllü reklam henüz hazır değil, lütfen daha sonra tekrar deneyin.'),
                    ),
                  );
                }
              },
              child: const Text('Ödüllü Reklam Göster'),
            ),
            const SizedBox(height: 20),

            // Reklamları yeniden yükleme butonu
            ElevatedButton(
              onPressed: () {
                // Reklamları yeniden yükle
                adsProvider.reloadAds();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reklamlar yeniden yükleniyor...'),
                  ),
                );
              },
              child: const Text('Reklamları Yeniden Yükle'),
            ),
          ],
        ),
      ),
    );
  }
}
