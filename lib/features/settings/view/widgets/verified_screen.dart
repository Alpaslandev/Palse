import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';

class VerifiedScreen extends StatefulWidget {
  const VerifiedScreen({super.key});

  @override
  State<VerifiedScreen> createState() => _VerifiedScreenState();
}

class _VerifiedScreenState extends State<VerifiedScreen> {
  final CustomerService _customerService = CustomerService();
  // Stepper için aktif adım
  int _currentStep = 0;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Text controller'lar
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();

  // Doğrulama ID'si
  String? _verificationId;

  // Yükleniyor durumu
  bool _isLoading = false;

  // Sayfa hala görünür mü?
  bool _isActive = true;

  // Formatlanmış telefon numarası
  String _formattedPhoneNumber = '';

  // Kod gönderme tokeni (Android için)
  int? _resendToken;

  // SMS kodu girişi için FocusNode
  final FocusNode _smsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Kullanıcının oturum açık olduğundan emin olalım
    if (_auth.currentUser == null) {
      debugPrint('Hata: Kullanıcı oturumu açık değil!');
      Future.microtask(() {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce oturum açmanız gerekiyor')),
        );
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    _smsFocusNode.dispose();
    _isActive = false;
    super.dispose();
  }

  // Telefon numarasını formatla
  String _formatPhoneNumber(String rawPhoneNumber) {
    // Telefon numarasını formatlayalım
    String phoneNumber = rawPhoneNumber.trim();

    // Tüm boşlukları ve artı işaretlerini kaldıralım
    phoneNumber = phoneNumber.replaceAll(' ', '').replaceAll('+', '');

    // Tek bir artı işareti ekleyelim başına
    phoneNumber = '+$phoneNumber';

    return phoneNumber;
  }

  // Telefon numarası doğrulama işlemi
  Future<void> _verifyPhoneNumber() async {
    // Debug mesajı ekleyelim
    debugPrint('Telefon doğrulama başlatılıyor: ${_phoneController.text}');

    // Geçerli bir numara kontrolü yapalım
    String? validationError = _validatePhoneNumber(_phoneController.text);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    // Telefon numarasını formatlayalım
    _formattedPhoneNumber = _formatPhoneNumber(_phoneController.text);
    debugPrint('Formatlanmış telefon numarası: $_formattedPhoneNumber');

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase doğrulama isteği gönder
      await _auth.verifyPhoneNumber(
        phoneNumber: _formattedPhoneNumber,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 120),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      debugPrint('Beklenmeyen hata: $e');
      _handleError(e.toString());
    }
  }

  // Otomatik doğrulama tamamlandığında (çoğunlukla Android için)
  Future<void> _onVerificationCompleted(PhoneAuthCredential credential) async {
    debugPrint('Otomatik doğrulama tamamlandı');

    if (!mounted || !_isActive) return;

    // Ortak başarı işlemlerini çağır
    await _handleAuthSuccess(credential);
  }

  // Doğrulama başarısız olduğunda
  void _onVerificationFailed(FirebaseAuthException e) {
    debugPrint('Doğrulama hatası: ${e.message}');
    debugPrint('Hata kodu: ${e.code}');

    if (!mounted || !_isActive) return;

    setState(() {
      _isLoading = false;
    });

    String errorMessage = 'Doğrulama hatası oluştu';

    // Hata kodlarına göre daha anlamlı mesajlar
    if (e.code == 'invalid-phone-number') {
      errorMessage = 'Geçersiz telefon numarası formatı';
    } else if (e.code == 'too-many-requests') {
      errorMessage = 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin';
    } else if (e.code == 'quota-exceeded') {
      errorMessage = 'SMS kotası aşıldı. Lütfen daha sonra tekrar deneyin';
    } else if (e.code == 'captcha-check-failed') {
      errorMessage = 'Captcha doğrulaması başarısız oldu. Tekrar deneyin';
    } else if (e.code == 'app-not-authorized') {
      errorMessage = 'Uygulama Firebase Authentication kullanmaya yetkili değil';
    } else {
      errorMessage = 'Hata: ${e.message}';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'ANLADIM',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  // Kod gönderildiğinde
  void _onCodeSent(String verificationId, int? resendToken) {
    debugPrint('Doğrulama kodu gönderildi. VerificationId: $verificationId');

    if (!mounted || !_isActive) return;

    setState(() {
      _verificationId = verificationId;
      _resendToken = resendToken;
      _isLoading = false;
      _currentStep = 1; // Bir sonraki adıma geç
    });

    // SMS kodu giriş alanına odaklan
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _smsFocusNode.requestFocus();
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğrulama kodu gönderildi')),
      );
    }
  }

  // Kod otomatik alınamadığında timeout
  void _onCodeAutoRetrievalTimeout(String verificationId) {
    debugPrint('Kod alma zaman aşımı. VerificationId: $verificationId');

    if (!mounted || !_isActive) return;

    setState(() {
      _verificationId = verificationId;
      _isLoading = false;
    });
  }

  // SMS kodu doğrulama
  Future<void> _verifySmsCode() async {
    debugPrint('SMS kodu doğrulanıyor: ${_smsController.text}');

    if (_smsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen doğrulama kodunu girin')),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // VerificationId kontrolü
      if (_verificationId == null) {
        throw Exception('Doğrulama ID\'si bulunamadı. Lütfen tekrar deneyin.');
      }

      // SMS kodu ile credential oluştur
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsController.text,
      );

      // Başarı işlemlerini çağır
      await _handleAuthSuccess(credential);
    } catch (e) {
      _handleError(e.toString());
    }
  }

  // Başarılı doğrulama işlemlerini yönet
  Future<void> _handleAuthSuccess(PhoneAuthCredential credential) async {
    try {
      // Kullanıcı var mı kontrol et
      if (_auth.currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Mevcut kullanıcıya phone number ekle
      await _auth.currentUser!.linkWithCredential(credential);

      // Firestore'da kullanıcı bilgilerini güncelle
      await _customerService.updateCustomerVerifiedAndPhone(_auth.currentUser!.uid, true, _formattedPhoneNumber);
      debugPrint('Firestore kullanıcı bilgileri güncellendi');

      if (!mounted || !_isActive) return;

      setState(() {
        _isLoading = false;
      });

      // Başarılı doğrulama mesajı
      debugPrint('Telefon numarası doğrulandı ve kullanıcıya bağlandı');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefon numarası başarıyla doğrulandı')),
        );

        // Başarılı olduğunda önceki sayfaya dön
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Credential işleme hatası: $e');

      // Hata provider-already-linked ise, telefon zaten doğrulanmış demektir
      if (e is FirebaseAuthException && e.code == 'provider-already-linked') {
        _handlePhoneAlreadyVerified();
      } else {
        _handleError(e.toString());
      }
    }
  }

  // Telefon numarası zaten doğrulanmış durumunu yönet
  Future<void> _handlePhoneAlreadyVerified() async {
    try {
      // Firestore'da kullanıcı bilgilerini güncelle
      if (_auth.currentUser != null) {
        await _customerService.updateCustomerVerifiedAndPhone(_auth.currentUser!.uid, true, _formattedPhoneNumber);
        debugPrint('Telefon zaten doğrulanmış, Firestore bilgileri güncellendi');
      }

      setState(() {
        _isLoading = false;
      });

      // Kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefon numarası zaten doğrulanmış')),
        );
        // Başarılı olduğunda önceki sayfaya dön
        Navigator.pop(context);
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  // Hata yönetimi
  void _handleError(String errorMessage) {
    if (!mounted || !_isActive) return;

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $errorMessage')),
      );
    }
  }

  // Telefon numarası formatını kontrol et
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen telefon numaranızı girin';
    }

    // Boşlukları kaldır
    String cleanValue = value.trim();

    // Sadece rakam ve + işareti kontrolü (daha esnek)
    final validChars = RegExp(r'[0-9+ ]');
    for (int i = 0; i < cleanValue.length; i++) {
      if (!validChars.hasMatch(cleanValue[i])) {
        return 'Geçersiz karakterler içeriyor (sadece rakam, + ve boşluk kullanın)';
      }
    }

    // Minimum uzunluk kontrolü
    if (cleanValue.replaceAll(' ', '').length < 10) {
      return 'Telefon numarası çok kısa';
    }

    return null;
  }

  // Kod tekrar gönderme
  Future<void> _resendVerificationCode() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Telefon numarası kontrolü
    if (_formattedPhoneNumber.isEmpty) {
      _formattedPhoneNumber = _formatPhoneNumber(_phoneController.text);
    }

    debugPrint('Yeniden kod gönderiliyor: $_formattedPhoneNumber');

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _formattedPhoneNumber,
        verificationCompleted: _onVerificationCompleted,
        verificationFailed: _onVerificationFailed,
        codeSent: _onCodeSent,
        codeAutoRetrievalTimeout: _onCodeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 120),
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      debugPrint('Kod yeniden gönderme hatası: $e');
      _handleError(e.toString());
    }
  }

  // Geri tuşuna basıldığında çağrılacak fonksiyon
  void _handlePopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop) {
      // Eğer kod gönderilmişse ve ikinci adımdaysak geri dönüşü engelle
      if (_currentStep == 1 && _verificationId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doğrulama işlemi devam ediyor. Lütfen kodu girin veya işlemi tamamlayın.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // Kod gönderildikten sonra geri dönüşü engelle
      canPop: _currentStep == 0 || _verificationId == null,
      onPopInvokedWithResult: _handlePopInvokedWithResult,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Telefon Doğrulama'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          // Kod gönderildikten sonra geri butonu devre dışı bırak
          automaticallyImplyLeading: _currentStep == 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Theme.of(context).colorScheme.background,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: _currentStep == 0 ? _buildPhoneNumberStep() : _buildVerificationCodeStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Telefon numarası adımı
  Widget _buildPhoneNumberStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Telefon doğrulama ikonu
          Icon(
            Icons.phone_android,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          // Başlık
          Text(
            'Telefon Numaranızı Doğrulayın',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Alt başlık
          Text(
            'Hesabınızı güvence altına almak için telefon numaranızı doğrulayın',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Telefon numarası giriş alanı
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Telefon Numarası',
                      hintText: '+90 5XX XXX XX XX',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: _validatePhoneNumber,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lütfen ülke kodu ile birlikte girin (örn: +90 5XX XXX XX XX)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyPhoneNumber,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Gönderiliyor...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        : const Text(
                            'Doğrulama Kodu Gönder',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Bilgi kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade100.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bilgi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'SMS kodunun gelmesi biraz zaman alabilir. Lütfen en az 2 dakika bekleyin.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kod gelmediyse numaranızı kontrol edip tekrar deneyin.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Doğrulama kodu adımı
  Widget _buildVerificationCodeStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // SMS doğrulama ikonu
          Icon(
            Icons.sms,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          // Başlık
          Text(
            'Doğrulama Kodunu Girin',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Alt başlık
          Text(
            'Telefonunuza gönderilen 6 haneli kodu girin',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Telefon numarası bilgisi
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Kod $_formattedPhoneNumber numarasına gönderildi',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          // Doğrulama kodu giriş alanı
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _smsController,
                    focusNode: _smsFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Doğrulama Kodu',
                      hintText: '6 haneli kod',
                      prefixIcon: const Icon(Icons.sms),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifySmsCode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Doğrulanıyor...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        : const Text(
                            'Doğrula',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _resendVerificationCode,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Kodu Tekrar Gönder'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Bilgi kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Önemli',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Doğrulama işlemi devam ederken lütfen uygulamadan çıkmayın.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kod gelmediyse "Kodu Tekrar Gönder" butonuna tıklayabilirsiniz.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
