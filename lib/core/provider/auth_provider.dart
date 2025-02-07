import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/auth/auth_service.dart';

// Auth durumunu yöneten provider sınıfı
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  User? _firebaseUser;
  Customer? _user;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  Customer? get user => _user;
  User? get firebaseUser => _firebaseUser;

  // Constructor'da auth state'i dinlemeye başla
  AuthProvider() {
    debugPrint('AuthProvider initialized');
    // Firebase auth durumu değişikliklerini dinle
    _authService.authStateChanges.listen((User? user) async {
      debugPrint('Auth State Changed: ${user?.email}');

      _isLoading = true;
      notifyListeners();

      _firebaseUser = user;

      if (user != null) {
        debugPrint('User logged in, loading data...');
        await _loadUserData();
      } else {
        debugPrint('User logged out');
        _user = null;
      }

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
      _firebaseUser = user;

      // TODO: Firestore'dan kullanıcı bilgilerini çek
      // _user = await _firestoreService.getCustomer(user!.uid);
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

      // TODO: Firestore'dan kullanıcı bilgilerini çek
      // _user = await _firestoreService.getCustomer(user!.uid);
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
    try {
      debugPrint('Loading user data');
      // TODO: Firestore'dan kullanıcı verilerini yükle
      // Örnek:
      // final userData = await _firestoreService.getUser(_firebaseUser!.uid);
      // _user = Customer.fromMap(userData);

      // Şimdilik basit bir Customer objesi oluşturalım
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }
}
