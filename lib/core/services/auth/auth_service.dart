import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Email ve şifre ile kayıt hatası: $e');
      throw Exception('Email ve şifre ile kayıt yapılırken bir hata oluştu.');
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);

      return credential.user;
    } on FirebaseAuthException catch (exception, s) {
      debugPrint('$exception$s');
      switch ((exception).code) {
        case 'invalid-email':
          throw Exception('Geçersiz email adresi.');
        case 'wrong-password':
          throw Exception('Yanlış şifre ya da email girdiniz.');
        case 'user-not-found':
          throw Exception('Bu email adresi ile kayıtlı kullanıcı bulunamadı.');
        case 'user-disabled':
          throw Exception('Bu kullanıcı hesabı devre dışı bırakılmış.');
        case 'too-many-requests':
          throw Exception('Çok fazla giriş denemesi yaptınız. Lütfen daha sonra tekrar deneyin.');
      }
      throw Exception('Beklenmeyen bir Firebase hatası oluştu. Lütfen tekrar deneyin.');
    } catch (e, s) {
      debugPrint('$e$s');
      throw Exception('Giriş başarısız oldu. Lütfen tekrar deneyin.');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign In: Kullanıcı oturumu iptal etti');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Google kimlik doğrulama belirteçleri alınamadı');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e, s) {
      debugPrint('Google Sign In FirebaseAuthException: $e\nStackTrace: $s');

      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('Bu email adresi farklı bir giriş yöntemi ile zaten kullanılıyor.');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Geçersiz kimlik bilgileri. Lütfen tekrar deneyin.');
      } else if (e.code == 'operation-not-allowed') {
        throw Exception('Bu işlem şu anda kullanılamıyor.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Bu kullanıcı hesabı devre dışı bırakılmış.');
      } else if (e.code == 'user-not-found') {
        throw Exception('Bu email adresi ile kayıtlı kullanıcı bulunamadı.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Yanlış şifre girdiniz.');
      } else {
        throw Exception('Firebase kimlik doğrulama hatası: ${e.message}');
      }
    } on Exception catch (e, s) {
      debugPrint('Google Sign In Detailed Error: $e\nStackTrace: $s');

      if (e.toString().contains('network_error')) {
        throw Exception('İnternet bağlantınızı kontrol edin');
      } else if (e.toString().contains('sign_in_failed') || e.toString().contains('PlatformException')) {
        throw Exception('''
Google Play Servisleri hatası. Lütfen:
1. Google Play Servislerinin güncel olduğundan
2. Cihazda bir Google hesabı ekli olduğundan
3. İnternet bağlantınızın olduğundan
emin olun.''');
      }

      throw Exception('Google ile giriş yapılırken bir hata oluştu: ${e.toString()}');
    } catch (e, s) {
      debugPrint('Google Sign In Unexpected Error: $e\nStackTrace: $s');
      throw Exception('Google ile giriş yapılırken beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.');
    }
  }

  Future<User?> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      final userCredential = await _auth.signInWithProvider(appleProvider);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple Sign In Error: $e');
      throw Exception('Apple ile giriş yapılırken bir hata oluştu.');
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
