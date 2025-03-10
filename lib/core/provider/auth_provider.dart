import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/auth/auth_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/notification_service.dart';
import 'package:palseapp/features/achievement/achievement_manager.dart';
import 'package:palseapp/features/achievement/achievements.dart';

// Auth durumunu yöneten provider sınıfı
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final CustomerService _userService = CustomerService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  User? _firebaseUser;
  Customer? _user;
  bool _isFirstTime = true;
  // AchievementManager başlatıldı mı kontrolü
  bool _isAchievementManagerInitialized = false;

  // Getterlar
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  Customer? get user => _user;
  User? get firebaseUser => _firebaseUser;
  bool get isProfileSetupCompleted => _user != null;

  StreamSubscription<DocumentSnapshot<Object?>>? _userStreamSubscription;

  // Constructor'da sadece log
  AuthProvider() {
    debugPrint('AuthProvider initialized');
  }

  // Initialize metodu - dışarıdan çağrılacak
  Future<void> initializeAuth() async {
    debugPrint('Initializing auth state...');
    try {
      _isLoading = true;
      notifyListeners();

      // Auth state'i dinlemeye başla
      _authService.authStateChanges.listen((User? user) async {
        debugPrint('Auth State Changed: ${user?.email}');
        _firebaseUser = user;

        await _userStreamSubscription?.cancel();
        _userStreamSubscription = null;

        if (user != null) {
          debugPrint('User logged in');
          _startFirestoreStream(user.uid);
        } else {
          debugPrint('User logged out');
          _user = null;
        }

        notifyListeners();
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kullanıcı verilerini stream olarak dinlemeye başla
  void _startFirestoreStream(String userId) {
    debugPrint('Starting user stream for user: $userId');

    _userStreamSubscription = _userService.streamFirestore(userId).listen((userData) {
      if (userData.exists && userData.data() != null) {
        _user = Customer.fromJson(userData.data() as Map<String, dynamic>, userId);
        if (_isFirstTime) {
          _isFirstTime = false;
          _notificationService.saveUserToken(userId);
          debugPrint('User token saved');
          // AchievementManager'ı başlat
          _initializeAchievementManager();
        } // Eğer AchievementManager zaten başlatılmışsa ve veri değişmişse
        else if (_isAchievementManagerInitialized && userData.exists) {
          // XP ve görev verilerinde bir değişiklik olduysa
          // bu değişikliği AchievementManager'a yansıt
          _updateAchievementManager();
        }

        debugPrint('User data: ${_user?.toJson()}');
      } else {
        debugPrint('User data not found');
        _user = null;
      }
      notifyListeners();
      debugPrint('User data updated: ${_user?.userID}');
    }, onError: (error) {
      debugPrint('User stream error: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  // Email ile giriş
  Future<void> loginWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Login işlemi
      final user = await _authService.loginWithEmail(email, password);
      // Sonra user data ve profile durumu
      if (user != null) {
        _firebaseUser = user;
      }
      // Auth state listener otomatik olarak değişiklikleri yakalayacak
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Email ile kayıt
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signUpWithEmailAndPassword(email, password);
      if (user != null) {
        _firebaseUser = user;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Google ile giriş
  Future<void> loginWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signInWithGoogle();

      // Sonra user data ve profile durumu
      if (user != null) {
        _firebaseUser = user;
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Apple ile giriş
  Future<void> loginWithApple() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.signInWithApple();
      _firebaseUser = user;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // AchievementManager'ı başlat
  void _initializeAchievementManager() {
    if (_user != null && !_isAchievementManagerInitialized) {
      try {
        // String-tabanlı Map'i enum Map'e dönüştür
        final Map<XpEvent, int> completedTasks = {};
        _user!.completedTasks.forEach((key, value) {
          try {
            final event = XpEvent.values.firstWhere((e) => e.name == key);
            completedTasks[event] = value;
          } catch (e) {
            debugPrint('Bilinmeyen XpEvent: $key');
          }
        });

        // UserAchievements nesnesini oluştur
        final achievements = UserAchievements(
          totalXp: _user!.totalXp,
          completedTasks: completedTasks,
          lastDailyTaskDate: _user!.lastDailyTaskDate,
        );

        // Achievement Manager'ı başlat
        AchievementManager().initialize(achievements);

        // Değişiklikleri dinle
        AchievementManager().addListener(_onAchievementsChanged);

        // Flag'i güncelle
        _isAchievementManagerInitialized = true;

        debugPrint('Achievement Manager initialized successfully');
      } catch (e) {
        debugPrint('Achievement Manager initialization error: $e');
      }
    }
  }

  // AchievementManager'daki değişiklikleri dinleyen metod
  void _onAchievementsChanged(UserAchievements achievements) {
    // Firestore stream tarafından güncelleniyor olabileceği için
    // önce çift yönlü bir güncelleme oluşmaması için kontrol yap

    // Eğer değişiklik varsa Customer modelini güncelle
    if (_user != null &&
        (_user!.totalXp != achievements.totalXp ||
            _mapsDifferent(_user!.completedTasks, achievements.completedTasks.map((key, value) => MapEntry(key.name, value))) ||
            _datesNotEqual(_user!.lastDailyTaskDate, achievements.lastDailyTaskDate))) {
      // Güncellenmiş Customer modelini oluştur
      final updatedUser = _user!.copyWith(
        totalXp: achievements.totalXp,
        completedTasks: achievements.completedTasks.map((key, value) => MapEntry(key.name, value)),
        lastDailyTaskDate: achievements.lastDailyTaskDate,
      );

      // Yerel modeli güncelle
      _user = updatedUser;

      // Firebase'e kaydet (önemli: bu işlem _userStreamSubscription'ı tekrar tetikleyecek)
      _userService.updateCustomer(_user!.userID!, updatedUser);

      // UI güncelleme
      notifyListeners();

      debugPrint('User data updated from Achievement Manager');
    }
  }

  // Firestore'dan gelen verilere göre AchievementManager'ı güncelle
  void _updateAchievementManager() {
    // Önce mevcut durumu al
    final currentAchievements = AchievementManager().userAchievements;

    // Firestore'dan gelen verilerle karşılaştır
    if (currentAchievements.totalXp != _user!.totalXp ||
        _mapsDifferent(_user!.completedTasks, _convertEnumMapToStringMap(currentAchievements.completedTasks)) ||
        _datesNotEqual(currentAchievements.lastDailyTaskDate, _user!.lastDailyTaskDate)) {
      // AchievementManager'daki dinleyiciyi geçici olarak kaldır
      // (çift güncelleme olmasın)
      AchievementManager().removeListener(_onAchievementsChanged);

      // Yeni değerleri hazırla
      final Map<XpEvent, int> completedTasks = _parseToEnumMap(_user!.completedTasks);

      // UserAchievements nesnesini oluştur
      final achievements = UserAchievements(
        totalXp: _user!.totalXp,
        completedTasks: completedTasks,
        lastDailyTaskDate: _user!.lastDailyTaskDate,
      );

      // Achievement Manager'ı güncelle
      AchievementManager().initialize(achievements);

      // Dinleyiciyi tekrar ekle
      AchievementManager().addListener(_onAchievementsChanged);

      debugPrint('Achievement Manager updated from Firestore data');
    }
  }

  // String map'i XpEvent map'e dönüştüren yardımcı metod
  Map<XpEvent, int> _parseToEnumMap(Map<String, int> stringMap) {
    final result = <XpEvent, int>{};
    stringMap.forEach((key, value) {
      try {
        final event = XpEvent.values.firstWhere((e) => e.name == key);
        result[event] = value;
      } catch (e) {
        debugPrint('Bilinmeyen XpEvent: $key');
      }
    });
    return result;
  }

  // XpEvent map'i String map'e dönüştüren yardımcı metod
  Map<String, int> _convertEnumMapToStringMap(Map<XpEvent, int> enumMap) {
    return enumMap.map((key, value) => MapEntry(key.name, value));
  }

  // İki map'in içeriğinin farklı olup olmadığını kontrol eden yardımcı metod
  bool _mapsDifferent(Map<String, int> map1, Map<String, int> map2) {
    if (map1.length != map2.length) return true;

    for (final entry in map1.entries) {
      if (!map2.containsKey(entry.key) || map2[entry.key] != entry.value) {
        return true;
      }
    }

    return false;
  }

  // İki tarih nesnesinin eşit olup olmadığını kontrol eden yardımcı metod
  bool _datesNotEqual(DateTime? date1, DateTime? date2) {
    if (date1 == null && date2 == null) return false;
    if (date1 == null || date2 == null) return true;

    return date1.year != date2.year || date1.month != date2.month || date1.day != date2.day;
  }

  // Çıkış yap
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      // AchievementManager dinleyicisini kaldır
      if (_isAchievementManagerInitialized) {
        AchievementManager().removeListener(_onAchievementsChanged);
        _isAchievementManagerInitialized = false;
      }
      await _authService.signOut();
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dispose metodu
  @override
  void dispose() {
    // AchievementManager dinleyicisini kaldır
    if (_isAchievementManagerInitialized) {
      AchievementManager().removeListener(_onAchievementsChanged);
    }

    _userStreamSubscription?.cancel();
    super.dispose();
  }
}
