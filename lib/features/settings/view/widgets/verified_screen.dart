import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/localization/app_localizations.dart'; // Localization için import
import 'package:intl_phone_number_field/intl_phone_number_field.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart'; // Formatter için import

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

  // Telefon numarası için IntPhoneNumber
  IntPhoneNumber _phoneNumber = IntPhoneNumber(code: "TR", dial_code: "+90", number: "");

  // Form key doğrulama için
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Telefon numarası geçerli mi?
  bool _isPhoneValid = false;

  @override
  void initState() {
    super.initState();

    // Kullanıcının oturum açık olduğundan emin olalım
    if (_auth.currentUser == null) {
      debugPrint('Hata: Kullanıcı oturumu açık değil!');
      Future.microtask(() {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('login_required'))),
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
  String _formatPhoneNumber(IntPhoneNumber phoneNumber) {
    // Telefon numarasını formatlayalım
    if (phoneNumber.rawNumber.isEmpty) {
      return "";
    }

    // rawDialCode ve rawNumber'ı birleştirerek tam telefon numarasını oluştur
    // + işareti olmadan alan kodu ve numarayı birleştir
    return phoneNumber.rawDialCode + phoneNumber.rawNumber;
  }

  // Telefon numarası doğrulama işlemi
  Future<void> _verifyPhoneNumber() async {
    // Form doğrulamasını kontrol et
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_enter_phone'))),
      );
      return;
    }

    // Debug mesajı ekleyelim
    debugPrint('Telefon doğrulama başlatılıyor: ${_phoneNumber.rawFullNumber}');

    // Telefon numarasını formatlayalım - + işareti ile başlayacak şekilde
    _formattedPhoneNumber = "+${_formatPhoneNumber(_phoneNumber)}";
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

    String errorMessage = context.tr('verification_error');

    // Hata kodlarına göre daha anlamlı mesajlar
    if (e.code == 'invalid-phone-number') {
      errorMessage = context.tr('invalid_phone_format');
    } else if (e.code == 'too-many-requests') {
      errorMessage = context.tr('too_many_requests');
    } else if (e.code == 'quota-exceeded') {
      errorMessage = context.tr('quota_exceeded');
    } else if (e.code == 'captcha-check-failed') {
      errorMessage = context.tr('captcha_failed');
    } else if (e.code == 'app-not-authorized') {
      errorMessage = context.tr('app_not_authorized');
    } else {
      errorMessage = '${context.tr('error_prefix')}${e.message}';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: context.tr('understood'),
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
        SnackBar(content: Text(context.tr('code_sent'))),
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
        SnackBar(content: Text(context.tr('please_enter_code'))),
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
        throw Exception(context.tr('verification_id_not_found'));
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
        throw Exception(context.tr('user_session_not_found'));
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
          SnackBar(content: Text(context.tr('phone_verified_success'))),
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
          SnackBar(content: Text(context.tr('phone_already_verified'))),
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
        SnackBar(content: Text('${context.tr('error_prefix')}$errorMessage')),
      );
    }
  }

  // Telefon numarası formatını kontrol et - artık pakete bırakıyoruz
  String? _validatePhoneNumber(IntPhoneNumber number) {
    if (number.number.isEmpty) {
      _isPhoneValid = false;
      return context.tr('please_enter_phone');
    }

    // IntPhoneNumber'ın alanlarını kontrol edelim
    debugPrint('Validasyon - Numara: ${number.number}');
    debugPrint('Validasyon - Alan Kodu: ${number.dial_code}');
    debugPrint('Validasyon - Ülke Kodu: ${number.code}');
    debugPrint('Validasyon - Raw Number: ${number.rawNumber}');

    // Eğer numara gerçekten boşsa
    if (number.rawNumber.isEmpty) {
      _isPhoneValid = false;
      return context.tr('please_enter_phone');
    }

    // Minimum uzunluk kontrolü (ülkeye göre değişebilir, genel olarak 7-10 arası)
    if (number.rawNumber.length < 7) {
      _isPhoneValid = false;
      return context.tr('phone_too_short');
    }

    _isPhoneValid = true;
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
      _formattedPhoneNumber = "+${_formatPhoneNumber(_phoneNumber)}";
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
          SnackBar(
            content: Text(context.tr('verification_in_progress_enter_code')),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema renklerini al
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope<Object?>(
      // Kod gönderildikten sonra geri dönüşü engelle
      canPop: _currentStep == 0 || _verificationId == null,
      onPopInvokedWithResult: _handlePopInvokedWithResult,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('phone_verification')),
          centerTitle: true,
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          // Kod gönderildikten sonra geri butonu devre dışı bırak
          automaticallyImplyLeading: _currentStep == 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withOpacity(0.05),
                colorScheme.surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: _currentStep == 0 ? _buildPhoneNumberStep(theme) : _buildVerificationCodeStep(theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Telefon numarası adımı
  Widget _buildPhoneNumberStep(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Telefon doğrulama ikonu
          Icon(
            Icons.phone_android,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          // Başlık
          Text(
            context.tr('verify_your_phone'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Alt başlık
          Text(
            context.tr('verify_phone_subtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
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
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TextFormField yerine InternationalPhoneNumberInput kullanıyoruz
                    InternationalPhoneNumberInput(
                      height: 60,
                      controller: _phoneController,
                      initCountry: CountryCodeModel(name: "Turkey", dial_code: "+90", code: "TR"),
                      onInputChanged: (phone) {
                        setState(() {
                          _phoneNumber = phone;
                          // Validator'ı çağır
                          _validatePhoneNumber(phone);
                        });
                        debugPrint('Telefon: ${phone.rawFullNumber}');
                        debugPrint('Alan Kodu: ${phone.rawDialCode}');
                        debugPrint('Numara: ${phone.rawNumber}');
                      },
                      formatter: MaskedInputFormatter('### ### ## ##'),
                      validator: _validatePhoneNumber,
                      phoneConfig: PhoneConfig(
                        focusedColor: colorScheme.primary,
                        enabledColor: colorScheme.primary,
                        errorColor: colorScheme.error,
                        radius: 12,
                        hintText: context.tr('phone_number_hint'),
                        borderWidth: 2,
                        backgroundColor: theme.inputDecorationTheme.fillColor,
                        textStyle: theme.textTheme.bodyLarge!,
                        hintStyle: TextStyle(
                          color: theme.hintColor,
                          fontSize: 16,
                        ),
                        errorStyle: TextStyle(
                          color: colorScheme.error,
                          fontSize: 12,
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        popUpErrorText: true,
                      ),
                      countryConfig: CountryConfig(
                        decoration: BoxDecoration(
                          border: Border.all(width: 2, color: colorScheme.primary.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: theme.textTheme.bodyLarge!,
                      ),
                      dialogConfig: DialogConfig(
                        backgroundColor: theme.scaffoldBackgroundColor,
                        searchBoxBackgroundColor: theme.inputDecorationTheme.fillColor!,
                        searchBoxIconColor: colorScheme.primary,
                        topBarColor: colorScheme.primary,
                        selectedItemColor: colorScheme.primaryContainer,
                        textStyle: theme.textTheme.bodyMedium,
                        searchBoxTextStyle: theme.textTheme.bodyMedium,
                        titleStyle: theme.textTheme.titleLarge,
                        searchBoxHintStyle: TextStyle(
                          color: theme.hintColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('phone_number_info'),
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : (_isPhoneValid ? _verifyPhoneNumber : null),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
                        disabledForegroundColor: colorScheme.onPrimary.withOpacity(0.7),
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
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  context.tr('sending'),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            )
                          : Text(
                              context.tr('send_verification_code'),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Bilgi kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
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
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('info'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('sms_delay_info'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('check_number_retry'),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Doğrulama kodu adımı
  Widget _buildVerificationCodeStep(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // SMS doğrulama ikonu
          Icon(
            Icons.sms,
            size: 80,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          // Başlık
          Text(
            context.tr('enter_verification_code'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Alt başlık
          Text(
            context.tr('enter_6_digit_code'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Telefon numarası bilgisi
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              context.tr('code_sent_to').replaceAll('{phoneNumber}', _formattedPhoneNumber),
              style: theme.textTheme.bodyMedium,
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
                      labelText: context.tr('verification_code'),
                      hintText: context.tr('verification_code_hint'),
                      prefixIcon: const Icon(Icons.sms),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.inputDecorationTheme.fillColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
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
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
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
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                context.tr('verifying'),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        : Text(
                            context.tr('verify'),
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _resendVerificationCode,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('resend_code')),
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
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
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
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('important'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('verification_in_progress'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('resend_code_info'),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
