import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsProvider extends ChangeNotifier {
  // Test reklamları için ID'ler
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // Gerçek ortam için reklam ID'leri (sonradan değiştirilecek)
  static const String _interstitialAdUnitId = kDebugMode ? _testInterstitialAdUnitId : 'ca-app-pub-4607763683457173/8618320377';
  static const String _rewardedAdUnitId = kDebugMode ? _testRewardedAdUnitId : 'ca-app-pub-4607763683457173/9060091931';

  // Geçiş reklamı için değişkenler
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // Ödüllü reklam için değişkenler
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  // Reklam gösterim zaman kontrolü için değişken
  DateTime? _lastInterstitialAdShow;
  static const int _minimumSecondsBetweenAds = 120; // İki reklam arası minimum süre

  bool get isInterstitialAdReady => _isInterstitialAdReady;
  bool get isRewardedAdReady => _isRewardedAdReady;

  AdsProvider() {
    // Başlangıçta reklamları yükle
    _loadInterstitialAd();
    _loadRewardedAd();
    if (kDebugMode) {
      debugPrint('Reklamlar yüklendi');
    }
  }

  // Geçiş reklamını yükle
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          // Reklam başarıyla yüklendi
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          // Reklam kapatıldığında yeni bir reklam yükle
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isInterstitialAdReady = false;
              ad.dispose();
              _loadInterstitialAd(); // Yeni reklam yükle
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isInterstitialAdReady = false;
              ad.dispose();
              _loadInterstitialAd(); // Yeni reklam yükle
            },
          );

          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          // Reklam yüklenemedi
          _isInterstitialAdReady = false;
          print('Geçiş reklamı yüklenemedi: $error');

          // Birkaç saniye sonra tekrar dene
          Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
          notifyListeners();
        },
      ),
    );
  }

  // Ödüllü reklamı yükle
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          // Reklam başarıyla yüklendi
          _rewardedAd = ad;
          _isRewardedAdReady = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isRewardedAdReady = false;
              ad.dispose();
              _loadRewardedAd(); // Yeni reklam yükle
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isRewardedAdReady = false;
              ad.dispose();
              _loadRewardedAd(); // Yeni reklam yükle
            },
          );
          debugPrint('Ödüllü reklam yüklendi');

          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          // Reklam yüklenemedi
          _isRewardedAdReady = false;
          print('Ödüllü reklam yüklenemedi: $error');

          // Birkaç saniye sonra tekrar dene
          Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
          notifyListeners();
        },
      ),
    );
  }

  // Geçiş reklamını göster
  Future<bool> showInterstitialAd() async {
    // Reklam gösterim zaman kontrolü
    if (_lastInterstitialAdShow != null) {
      final difference = DateTime.now().difference(_lastInterstitialAdShow!);
      if (difference.inSeconds < _minimumSecondsBetweenAds) {
        if (kDebugMode) {
          print('Son reklam gösteriminden bu yana $_minimumSecondsBetweenAds saniye geçmedi');
        }
        return false;
      }
    }

    if (!_isInterstitialAdReady || _interstitialAd == null) {
      // Reklam hazır değilse yüklemeyi dene ve false döndür
      _loadInterstitialAd();
      return false;
    }

    // Reklamı göster
    await _interstitialAd!.show();
    _lastInterstitialAdShow = DateTime.now(); // Son gösterim zamanını güncelle
    _isInterstitialAdReady = false;
    notifyListeners();
    return true;
  }

  // Ödüllü reklamı göster ve ödül kazanınca geri çağrı yap
  Future<bool> showRewardedAd({Function? onRewarded}) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      // Reklam hazır değilse yüklemeyi dene ve false döndür
      _loadRewardedAd();
      return false;
    }

    // Ödül kazanıldığında işlem yap
    _rewardedAd!.setImmersiveMode(true);
    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // Kullanıcı ödül kazandı
        if (onRewarded != null) {
          onRewarded(reward.amount);
        }
      },
    );

    _isRewardedAdReady = false;
    notifyListeners();
    return true;
  }

  // Reklamları yeniden yükle
  void reloadAds() {
    if (!_isInterstitialAdReady) {
      _loadInterstitialAd();
    }

    if (!_isRewardedAdReady) {
      _loadRewardedAd();
    }
  }

  @override
  void dispose() {
    // Kullanılmayan reklamları temizle
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}


/*

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-4607763683457173/7152609705";
    } else if (Platform.isIOS) {
      return "ca-app-pub-4607763683457173/8618320377";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-4607763683457173/5001073176";
    } else if (Platform.isIOS) {
      return "ca-app-pub-4607763683457173/9060091931";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }



*/