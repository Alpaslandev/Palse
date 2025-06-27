import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/auth/auth_service.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/notification_service.dart';

// Auth durumunu yöneten provider sınıfı
class AuthProvider extends ChangeNotifier implements Listenable {
  final AuthService _authService = AuthService();
  final CustomerService _userService = CustomerService();
  final NotificationService _notificationService = NotificationService();
  final AdvertService _advertService = AdvertService();

  bool _isLoading = true;
  bool _isFirestoreDataLoaded =
      false; // Firestore verilerinin yüklenme durumunu takip eden flag
  User? _firebaseUser;
  Customer? _user;
  bool _isFirstTime = true;
  // Apple giriş bilgilerini saklayacak değişkenler
  String? _appleFirstName;
  String? _appleLastName;

  // Getterlar
  bool get isLoading =>
      _isLoading || (_firebaseUser != null && !_isFirestoreDataLoaded);
  bool get isProfileSetupCompleted => _user != null && _isFirestoreDataLoaded;
  Customer? get user => _user;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isFirestoreDataLoaded => _isFirestoreDataLoaded;
  String? get appleFirstName => _appleFirstName;
  String? get appleLastName => _appleLastName;

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
      _isFirestoreDataLoaded = false; // Başlangıçta false olarak ayarla
      notifyListeners();

      _authService.authStateChanges.listen((User? user) async {
        debugPrint('Auth State Changed: ${user?.email}');
        _firebaseUser = user;

        if (user == null) {
          _isFirestoreDataLoaded =
              true; // Kullanıcı yoksa veri yükleme tamamlandı sayılır
        } else {
          _isFirestoreDataLoaded =
              false; // Kullanıcı varsa veri yükleme başlıyor
        }

        notifyListeners();

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

    _userStreamSubscription =
        _userService.streamFirestore(userId).listen((userData) {
      debugPrint('Firestore verisi alındı: exists=${userData.exists}');

      if (userData.exists && userData.data() != null) {
        final newUser =
            Customer.fromJson(userData.data() as Map<String, dynamic>, userId);
        debugPrint(
            'Customer objesi oluşturuldu: id=${newUser.userID}, firstName=${newUser.firstName}');

        _user = newUser;
        _isFirestoreDataLoaded = true; // Firestore verisi yüklendi
        notifyListeners(); // Her durumda notifyListeners() çağrılması gerekiyor

        if (_isFirstTime) {
          _isFirstTime = false;
          _notificationService.saveUserToken(userId);
          _userService.updateUserLastSeen(userId);
          debugPrint('User token saved');
        }

        debugPrint('User data: ${_user?.toJson()}');
        debugPrint('Firestore data loaded: $_isFirestoreDataLoaded');
      } else {
        debugPrint('User data not found');
        _user = null;
        _isFirestoreDataLoaded =
            true; // Veri bulunamadı ama yükleme işlemi tamamlandı
        notifyListeners();
      }
      debugPrint('User data updated: ${_user?.userID}');
    }, onError: (error) {
      debugPrint('User stream error: $error');
      _isLoading = false;
      _isFirestoreDataLoaded =
          true; // Hata durumunda da yükleme işlemi tamamlandı sayılır
      notifyListeners();
    });
  }

  // Email ile giriş
  Future<void> loginWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _isFirestoreDataLoaded = false; // Giriş yaparken false olarak ayarla
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
      _isFirestoreDataLoaded = false; // Kayıt yaparken false olarak ayarla
      notifyListeners();

      final user =
          await _authService.signUpWithEmailAndPassword(email, password);
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
      debugPrint('Google ile giriş başlatılıyor...');
      _isLoading = true;
      _isFirestoreDataLoaded =
          false; // Google ile giriş yaparken false olarak ayarla
      notifyListeners();

      final user = await _authService.signInWithGoogle();

      // Sonra user data ve profile durumu
      if (user != null) {
        debugPrint('Google ile giriş başarılı: ${user.email}');
        _firebaseUser = user;
        notifyListeners();
      } else {
        debugPrint('Google ile giriş başarısız: User null döndü');
      }
    } catch (e) {
      debugPrint('Google ile giriş hatası: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint(
          'Google giriş durumu: isAuthenticated=${isAuthenticated}, isLoading=${isLoading}, isFirestoreDataLoaded=${isFirestoreDataLoaded}, user=${_user?.userID}');
    }
  }

  // Apple ile giriş
  Future<void> loginWithApple() async {
    try {
      _isLoading = true;
      _isFirestoreDataLoaded =
          false; // Apple ile giriş yaparken false olarak ayarla
      notifyListeners();

      final user = await _authService.signInWithApple();
      _firebaseUser = user;

      // Apple ile giriş yapıldığında kullanıcı bilgilerini alıyoruz
      if (user != null) {
        // DisplayName formatı genellikle "Ad Soyad" şeklindedir
        final displayName = user.displayName;
        if (displayName != null &&
            displayName.isNotEmpty &&
            displayName.contains(' ')) {
          final nameParts = displayName.split(' ');
          _appleFirstName = nameParts.first;
          _appleLastName = nameParts.length > 1 ? nameParts.last : '';
          debugPrint(
              'Apple ile giriş: Ad: $_appleFirstName, Soyad: $_appleLastName');
        }
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    _isFirestoreDataLoaded = false;
    await _userStreamSubscription?.cancel();
    _userStreamSubscription = null;
    notifyListeners();

    try {
      if (user != null && user!.adverts != null) {
        for (var advert in user!.adverts!) {
          await _advertService.deleteAdvert(advert, user!.userID!);
        }
      }
      await _userService.deleteAccount(user!.userID!);
      await _authService.signOut();
    } catch (e) {
      debugPrint('Kullanıcı silinirken hata oluştu: $e');
      rethrow;
    } finally {
      _isLoading = false;
      _isFirestoreDataLoaded = true;
      notifyListeners();
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    try {
      _isLoading = true;
      _isFirestoreDataLoaded = false;
      notifyListeners();
      await _authService.signOut();
      await _userService.resetFcmToken(user!.userID!);
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      _isFirestoreDataLoaded = true;
      notifyListeners();
    }
  }

  // Kullanıcı modelini güncelle
  void updateUser(Customer updatedUser) {
    _user = updatedUser;
    _isFirestoreDataLoaded = true;
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
