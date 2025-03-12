import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/auth/auth_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/notification_service.dart';

// Auth durumunu yöneten provider sınıfı
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final CustomerService _userService = CustomerService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  User? _firebaseUser;
  Customer? _user;
  bool _isFirstTime = true;

  // Getterlar
  bool get isLoading => _isLoading;
  bool get isProfileSetupCompleted => _user != null;
  Customer? get user => _user;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;

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

      _authService.authStateChanges.listen((User? user) async {
        debugPrint('Auth State Changed: ${user?.email}');
        _firebaseUser = user;
        notifyListeners();

        // await Future.delayed(const Duration(seconds: 4));

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
        final newUser = Customer.fromJson(userData.data() as Map<String, dynamic>, userId);

        // Önceki kullanıcı verisi ile yeni kullanıcı verisini karşılaştır
        final bool isPremiumChanged = _user?.isPremium != newUser.isPremium;

        _user = newUser;
        if (_isFirstTime) {
          _isFirstTime = false;
          _notificationService.saveUserToken(userId);
          _userService.updateUserLastSeen(userId);
          debugPrint('User token saved');
        }

        debugPrint('User data: ${_user?.toJson()}');

        // Sadece isPremium değişmişse bildirim gönder
        if (isPremiumChanged) {
          debugPrint('isPremium değişti: ${_user?.isPremium}');
          notifyListeners();
        } else {
          // Diğer değişiklikler için normal bildirim
          notifyListeners();
        }
      } else {
        debugPrint('User data not found');
        _user = null;
        notifyListeners();
      }
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

  // Kullanıcı modelini güncelle
  void updateUser(Customer updatedUser) {
    _user = updatedUser;
    notifyListeners();
    debugPrint('Kullanıcı modeli güncellendi: ${updatedUser.userID}');
  }

  // Dispose metodu
  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    super.dispose();
  }
}
