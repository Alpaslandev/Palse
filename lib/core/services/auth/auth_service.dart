import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google Sign In Error: $e');
      throw Exception('Google ile giriş yapılırken bir hata oluştu.');
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
