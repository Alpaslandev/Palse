import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/auth/auth_service.dart';

// Auth durumunu yöneten provider sınıfı
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  User? _firebaseUser;
  Customer? _user;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  Customer? get user => _user;
  User? get firebaseUser => _firebaseUser;

  AuthProvider() {
    // Firebase auth durumu değişikliklerini dinle
    _authService.authStateChanges.listen((User? user) {
      _firebaseUser = user;
      notifyListeners();
    });
  }

  // Email ile giriş
  Future<void> loginWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.loginWithEmail(email, password);
      _firebaseUser = user;

      // TODO: Firestore'dan kullanıcı bilgilerini çek ve Customer nesnesini oluştur
      // _user = await _firestoreService.getCustomer(user!.uid);
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
      await _authService.signOut();
      _firebaseUser = null;
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout Error: $e');
      rethrow;
    }
  }
}
