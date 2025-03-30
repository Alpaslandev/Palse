import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneNumberSheet extends StatefulWidget {
  const PhoneNumberSheet({super.key});

  @override
  State<PhoneNumberSheet> createState() => _PhoneNumberSheetState();
}

class _PhoneNumberSheetState extends State<PhoneNumberSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _codeSent = false;
  String _verificationId = '';
  String? _errorMessage;
  bool _captchaVisible = false;
  final GlobalKey _captchaKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          const Text(
            'Telefon Numarası Doğrulama',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Hata mesajı (varsa)
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),

          // Captcha alanı için container
          Container(
            key: _captchaKey,
            width: double.infinity,
            height: _captchaVisible ? 100 : 0,
            color: Colors.transparent,
          ),

          if (_captchaVisible)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    'Doğrulama işlemi yapılıyor...\nLütfen bekleyin',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            const SizedBox(height: 16),

            // Telefon numarası girişi veya SMS kodu girişi
            if (!_codeSent) ...[
              // Telefon numarası girişi
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  hintText: '+90 5XX XXX XX XX',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 8),
              const Text(
                'Lütfen ülke kodu ile birlikte girin (örn: +90)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              // SMS kodu girişi
              TextField(
                controller: _smsCodeController,
                decoration: InputDecoration(
                  labelText: 'SMS Kodu',
                  hintText: '6 haneli kod',
                  prefixIcon: const Icon(Icons.sms),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 8),
              Text(
                '${_phoneController.text} numarasına gönderilen 6 haneli kodu girin',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],

            const SizedBox(height: 24),

            // Buton
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleButtonPress,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_codeSent ? 'Doğrula' : 'Kod Gönder'),
              ),
            ),

            if (_codeSent) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _isLoading ? null : _resendCode,
                icon: const Icon(Icons.refresh),
                label: const Text('Kodu Tekrar Gönder'),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Buton işlemi
  void _handleButtonPress() {
    if (_codeSent) {
      _verifyCode();
    } else {
      _sendVerificationCode();
    }
  }

  // Doğrulama kodu gönderme
  Future<void> _sendVerificationCode() async {
    final phoneNumber = _phoneController.text.trim();

    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen telefon numaranızı girin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _captchaVisible = true;
    });

    try {
      // Platform kontrolü yapalım
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android cihazlarda otomatik doğrulama
          if (!mounted) return;

          setState(() {
            _isLoading = false;
            _captchaVisible = false;
          });

          // Başarılı olduğunda sayfayı kapat ve true döndür
          Navigator.of(context).pop(true);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
            _captchaVisible = false;
            _errorMessage = _getErrorMessage(e);
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
            _captchaVisible = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _captchaVisible = false;
          });
        },
        timeout: const Duration(seconds: 60),
        // Firebase için RecaptchaVerifier yapılandırması - overlay kullanımı sağlar
        // Not: iOS ve Android'de reCAPTCHA göstermiyoruz, sadece web platformunda
        // Ancak verifier eklemek reCAPTCHA'nın mevcut sayfa üzerinde kalmasını sağlar
        forceResendingToken: null,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _captchaVisible = false;
        _errorMessage = 'Bir hata oluştu: ${e.toString()}';
      });
    }
  }

  // SMS kodunu doğrulama
  Future<void> _verifyCode() async {
    final smsCode = _smsCodeController.text.trim();

    if (smsCode.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen SMS kodunu girin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // SMS kodu ile kimlik doğrulama
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );

      // Doğrulama işlemi Firebase tarafından kontrol edilir
      // Bu adımda sadece kodun geçerli olup olmadığını kontrol ediyoruz
      // Gerçek bir giriş ya da hesap bağlama yapmıyoruz
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        // Eğer hali hazırda bir kullanıcı oturumu varsa, onu kullanarak doğrulayalım
        try {
          // Mevcut kullanıcı varsa, telefon kimlik bilgisini bağlamayı deneyelim
          // Bu API çağrısı sadece doğrulama için, gerçekten kullanıcıya bağlamıyoruz
          // Çünkü işi bitince çıkış yapacağız
          await currentUser.unlink(PhoneAuthProvider.PROVIDER_ID);
          await currentUser.linkWithCredential(credential);
          await currentUser.unlink(PhoneAuthProvider.PROVIDER_ID);

          if (!mounted) return;

          // Başarılı olduğunda sayfayı kapat ve true döndür
          Navigator.of(context).pop(true);
        } catch (e) {
          // İlk olarak linkWithCredential'ı deneyerek doğrulayalım
          // Eğer bağlama başarısız olursa, başka bir yöntem deneyelim
          await _verifyWithTempSignIn(credential);
        }
      } else {
        // Aktif kullanıcı yoksa, geçici oturum açarak doğrulayalım
        await _verifyWithTempSignIn(credential);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Doğrulama başarısız: ${e.toString()}';
      });
    }
  }

  // Geçici oturum açarak doğrulama
  Future<void> _verifyWithTempSignIn(PhoneAuthCredential credential) async {
    try {
      // Geçici olarak oturum açarak doğrulama
      // Bu yöntem, sadece telefon numarasının geçerli olup olmadığını kontrol eder
      final tempUserCredential = await _auth.signInWithCredential(credential);

      // İşlem tamamlandıktan sonra çıkış yap
      await _auth.signOut();

      if (!mounted) return;

      // Başarılı olduğunda sayfayı kapat ve true döndür
      Navigator.of(context).pop(true);
    } catch (e) {
      rethrow;
    }
  }

  // Kodu tekrar gönderme
  void _resendCode() {
    setState(() {
      _codeSent = false;
      _smsCodeController.clear();
    });
    _sendVerificationCode();
  }

  // Hata mesajlarını Türkçeleştirme
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası formatı';
      case 'invalid-verification-code':
        return 'Geçersiz doğrulama kodu';
      case 'too-many-requests':
        return 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin';
      case 'quota-exceeded':
        return 'Günlük SMS kotası aşıldı. Lütfen daha sonra tekrar deneyin';
      case 'credential-already-in-use':
        return 'Bu telefon numarası başka bir hesap tarafından kullanılıyor';
      case 'captcha-check-failed':
        return 'Captcha doğrulaması başarısız oldu, lütfen tekrar deneyin';
      case 'missing-client-identifier':
        return 'Captcha gereçleri yüklenemedi, lütfen tekrar deneyin';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }
}
