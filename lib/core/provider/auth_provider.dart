import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/auth/auth_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/notification_service.dart';
import 'package:palseapp/core/services/achievement_service.dart';
import 'package:palseapp/features/achievement/achievements.dart';

// Auth durumunu yöneten provider sınıfı
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final CustomerService _userService = CustomerService();
  final NotificationService _notificationService = NotificationService();
  final AchievementService _achievementService = AchievementService();

  bool _isLoading = true;
  User? _firebaseUser;
  Customer? _user;
  bool _isFirstTime = true;

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

  // XP kazandırma metodu
  Future<void> earnXp(XpEvent event) async {
    if (_user == null) return;

    try {
      final updatedUser = await _achievementService.earnXp(_user!, event);

      if (updatedUser.totalXp != _user!.totalXp) {
        _user = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('XP kazanırken hata: $e');
    }
  }

  // Özel XP ekleme metodu
  Future<void> earnCustomXp(int amount) async {
    if (_user == null || amount <= 0) return;

    try {
      final updatedUser = await _achievementService.earnCustomXp(_user!, amount);

      if (updatedUser.totalXp != _user!.totalXp) {
        _user = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Özel XP eklerken hata: $e');
    }
  }

  // Günlük görevleri sıfırlama metodu
  Future<void> resetDailyTasks() async {
    if (_user == null) return;

    try {
      final updatedUser = await _achievementService.resetDailyTasks(_user!);
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Günlük görevleri sıfırlarken hata: $e');
    }
  }

  // Kullanıcının unvanını döndüren getter
  UserRank get userRank {
    if (_user == null) return UserRank.beginner;
    return _achievementService.getUserRank(_user!.totalXp);
  }

  // Kullanıcının görevi tamamlayıp tamamlamadığını kontrol eden metod
  bool isTaskCompleted(XpEvent event) {
    if (_user == null) return false;
    return _achievementService.isTaskCompleted(_user!, event);
  }

  // Bir görevin kaç kez tamamlandığını hesaplayan metod
  int getTaskCompletionCount(XpEvent event) {
    if (_user == null) return 0;
    return _achievementService.getTaskCompletionCount(_user!, event);
  }

  // Günlük görevin bugün tamamlanıp tamamlanmadığını kontrol eden metod
  bool isDailyTaskCompletedToday() {
    if (_user == null) return false;
    return _achievementService.isDailyTaskCompletedToday(_user!);
  }

  // Kullanıcının kazandığı premium ödül sayısını döndüren metod
  int getEarnedPremiumRewardCount() {
    if (_user == null) return 0;
    return _achievementService.getEarnedPremiumRewardCount(_user!.totalXp);
  }

  // Bir sonraki premium ödüle ne kadar XP kaldığını hesaplayan metod
  int getXpToNextPremium() {
    if (_user == null) return 0;
    return _achievementService.getXpToNextPremium(_user!.totalXp);
  }

  // Çıkış yap
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
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
    _userStreamSubscription?.cancel();
    super.dispose();
  }
}
