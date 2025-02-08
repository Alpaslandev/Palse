import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/auth/auth_service.dart';
import 'package:palseapp/core/services/firestore/user_service.dart';

// Auth durumunu yöneten provider sınıfı
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = true;
  bool _isInitialized = false; // Yeni eklenen flag
  User? _firebaseUser;
  Customer? _user;
  bool _isProfileSetupCompleted = false;

  // Getterlar
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  Customer? get user => _user;
  User? get firebaseUser => _firebaseUser;
  bool get isProfileSetupCompleted => _isProfileSetupCompleted;

  // Constructor'da sadece log
  AuthProvider() {
    debugPrint('AuthProvider initialized');
  }
  // Batch update için yeni metod
  void _batchUpdate({
    required bool isLoading,
    required bool isInitialized,
    bool? isProfileCompleted,
  }) {
    _isLoading = isLoading;
    _isInitialized = isInitialized;
    if (isProfileCompleted != null) {
      _isProfileSetupCompleted = isProfileCompleted;
    }
    notifyListeners(); // Tek bir notify
  }

  // Initialize metodu - dışarıdan çağrılacak
  Future<void> initializeAuth() async {
    if (_isInitialized) return; // Eğer zaten initialize edildiyse tekrar etme

    debugPrint('Initializing auth state...');
    try {
      _isLoading = true;
      notifyListeners();

      // Auth state'i dinlemeye başla
      _authService.authStateChanges.listen((User? user) async {
        debugPrint('Auth State Changed: ${user?.email}');
        _firebaseUser = user;

        if (user != null) {
          debugPrint('User logged in');
          await _loadUserData();
        } else {
          debugPrint('User logged out');
          _user = null;
          _isProfileSetupCompleted = false;
        }

        notifyListeners();
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Email ile giriş
  Future<void> loginWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Login işlemi
      await _authService.loginWithEmail(email, password);
      // Auth state listener otomatik olarak değişiklikleri yakalayacak
    } catch (e) {
      debugPrint('Login error: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
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
        await _loadUserData(); // Profile setup durumu burada güncelleniyor

        // En son tek bir state update
        _isLoading = false;
        notifyListeners(); // Router bu notify ile tüm güncel durumu alacak
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
      await _loadUserData();
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

  Future<void> _loadUserData() async {
    if (_firebaseUser == null) return;
    try {
      _isLoading = true;
      notifyListeners();
      debugPrint('Firebase user: ${_firebaseUser?.uid}');
      _user = await _userService.getCurrentUser(_firebaseUser!.uid);
      _isProfileSetupCompleted = _user != null;
      debugPrint('User data loaded');
    } catch (e) {
      debugPrint('Error loading user data: $e');
      _isProfileSetupCompleted = false;
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
