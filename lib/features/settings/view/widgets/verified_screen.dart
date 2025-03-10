import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter/services.dart';

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

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Sayfa hala görünür mü?
  bool _isActive = true;

  // Formatlanmış telefon numarası
  String _formattedPhoneNumber = '';

  // Doğrulama kodunu elle giren (test) kullanıcılar için manuel doğrulama
  bool _manualVerification = false;

  // iOS için reCAPTCHA container key
  final GlobalKey _recaptchaKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Kullanıcının oturum açık olduğundan emin olalım
    if (_auth.currentUser == null) {
      debugPrint('Hata: Kullanıcı oturumu açık değil!');
      // Burada kullanıcıyı login sayfasına yönlendirebilirsiniz
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
    _isActive = false;
    super.dispose();
  }

  // Telefon numarası doğrulama işlemi
  Future<void> _verifyPhoneNumber() async {
    // Debug mesajı ekleyelim
    debugPrint('Telefon doğrulama başlatılıyor: ${_phoneController.text}');

    // Telefon numarasını formatlayalım
    String phoneNumber = _phoneController.text.trim();

    // Tüm boşlukları ve artı işaretlerini kaldıralım
    phoneNumber = phoneNumber.replaceAll(' ', '').replaceAll('+', '');

    // Tek bir artı işareti ekleyelim başına
    phoneNumber = '+$phoneNumber';

    // Sınıf değişkenine atayalım ki sonra Firestore güncellemesi yaparken kullanabilelim
    _formattedPhoneNumber = phoneNumber;

    debugPrint('Formatlanmış telefon numarası: $phoneNumber');

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Platform kontrolü yapalım
    if (Platform.isIOS) {
      // iOS için özel doğrulama akışını başlat
      _initIOSPhoneVerification(phoneNumber);
    } else {
      // Android ve diğer platformlar için normal doğrulama
      _verifyPhoneNumberForNonIOS(phoneNumber);
    }
  }

  // iOS için telefon doğrulama
  Future<void> _initIOSPhoneVerification(String phoneNumber) async {
    try {
      debugPrint('iOS için telefon doğrulama başlatılıyor');

      // Test numarası kontrolü
      bool useTestNumber = true; // Test için
      if (useTestNumber) {
        phoneNumber = '+905055555555'; // Firebase konsolunda eklediğiniz test numarası
        debugPrint('Test numarası kullanılıyor: $phoneNumber');
      }

      // iOS için doğrulama
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // iOS'ta otomatik doğrulama pek çalışmaz, manuel kod girişi gerekir
          debugPrint('Otomatik doğrulama tamamlandı (iOS\'ta nadir)');

          // Otomatik doğrulama durumunda kullanıcıya telefon numarası ekle
          if (!mounted || !_isActive) return;

          try {
            // Mevcut kullanıcıya credential ekle
            await _auth.currentUser?.linkWithCredential(credential);
            debugPrint('Telefon numarası mevcut kullanıcıya bağlandı');

            // Firestore'da kullanıcı bilgilerini güncelle
            if (_auth.currentUser != null) {
              await _customerService.updateCustomerVerifiedAndPhone(_auth.currentUser!.uid, true, _formattedPhoneNumber);
              debugPrint('Firestore kullanıcı bilgileri güncellendi');
            }

            setState(() {
              _isLoading = false;
              _currentStep = 0; // İşlem tamamlandı
            });

            // Kullanıcıya bilgi ver
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Telefon numarası başarıyla doğrulandı')),
              );
              // Başarılı olduğunda önceki sayfaya dön
              Navigator.pop(context);
            }
          } catch (e) {
            debugPrint('Credential ekleme hatası: $e');

            // Hata FirebaseAuthException ve error code'u provider-already-linked ise
            // Telefon numarası zaten doğrulanmış demektir
            if (e is FirebaseAuthException && e.code == 'provider-already-linked') {
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
            } else {
              setState(() {
                _isLoading = false;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Doğrulama hatası: $e')),
                );
              }
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('iOS doğrulama hatası: ${e.message}');

          if (!mounted || !_isActive) return;

          setState(() {
            _isLoading = false;
            // Manuel doğrulama için arayüzü hazırla
            _manualVerification = true;
          });

          String errorMessage = 'iOS doğrulama hatası oluştu';

          // Hata kodlarına göre daha anlamlı mesajlar
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Geçersiz telefon numarası formatı';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin';
          } else {
            errorMessage = 'Hata: ${e.message}';
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('iOS\'ta doğrulama kodu gönderildi. VerificationId: $verificationId');

          if (!mounted || !_isActive) return;

          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
            _currentStep = 1; // Bir sonraki adıma geç
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Doğrulama kodu gönderildi')),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('iOS\'ta kod alma zaman aşımı');

          if (!mounted || !_isActive) return;

          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
        timeout: const Duration(seconds: 120),
        forceResendingToken: null,
      );
    } catch (e) {
      debugPrint('iOS telefon doğrulama hatası: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('iOS doğrulama hatası: $e')),
      );
    }
  }

  // Android ve diğer platformlar için telefon doğrulama
  Future<void> _verifyPhoneNumberForNonIOS(String phoneNumber) async {
    try {
      // "Unusual Activity" hatasını önlemek için Firebase test numarasını kullanın
      bool useTestNumber = true; // Test numarası kullanmak için true yapın - DENEME İÇİN ETKİNLEŞTİRİLDİ

      if (useTestNumber) {
        // Test numarası için
        phoneNumber = '+905055555555'; // Firebase konsolunda eklediğiniz test numarası (değiştirin)
        debugPrint('Test numarası kullanılıyor: $phoneNumber');
      }

      // Mobil platformlar için verifyPhoneNumber kullanılır
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Otomatik doğrulama (Android'de çalışabilir)
          debugPrint('Otomatik doğrulama tamamlandı');

          // Otomatik doğrulama durumunda kullanıcıya telefon numarası ekle
          if (!mounted || !_isActive) return;

          try {
            // Mevcut kullanıcıya credential ekle
            await _auth.currentUser?.linkWithCredential(credential);
            debugPrint('Telefon numarası mevcut kullanıcıya bağlandı');

            // Firestore'da kullanıcı bilgilerini güncelle
            if (_auth.currentUser != null) {
              await _customerService.updateCustomerVerifiedAndPhone(_auth.currentUser!.uid, true, _formattedPhoneNumber);
              debugPrint('Firestore kullanıcı bilgileri güncellendi');
            }

            setState(() {
              _isLoading = false;
              _currentStep = 0; // İşlem tamamlandı
            });

            // Kullanıcıya bilgi ver
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Telefon numarası başarıyla doğrulandı')),
              );
              // Başarılı olduğunda önceki sayfaya dön
              Navigator.pop(context);
            }
          } catch (e) {
            debugPrint('Credential ekleme hatası: $e');

            // Hata FirebaseAuthException ve error code'u provider-already-linked ise
            // Telefon numarası zaten doğrulanmış demektir
            if (e is FirebaseAuthException && e.code == 'provider-already-linked') {
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
            } else {
              setState(() {
                _isLoading = false;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Doğrulama hatası: $e')),
                );
              }
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Doğrulama hatası: ${e.message}');
          debugPrint('Hata kodu: ${e.code}');

          if (!mounted || !_isActive) return;

          setState(() {
            _isLoading = false;
            // Manuel doğrulama için arayüzü hazırla
            _manualVerification = true;
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
          } else if (e.code == 'web-context-cancelled') {
            errorMessage = 'Web doğrulama iptal edildi';
          } else if (e.message?.contains('blocked') == true || e.message?.contains('unusual activity') == true) {
            errorMessage =
                'Bu cihazdan yapılan istekler geçici olarak engellendi. Firebase konsolundan test numarası ekleyin veya daha sonra tekrar deneyin.';
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
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Doğrulama kodu gönderildi. VerificationId: $verificationId');

          if (!mounted || !_isActive) return;

          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
            _currentStep = 1; // Bir sonraki adıma geç
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Doğrulama kodu gönderildi')),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Kod alma zaman aşımı. VerificationId: $verificationId');

          if (!mounted || !_isActive) return;

          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        },
        // Daha uzun bir timeout süresi
        timeout: const Duration(seconds: 120),
        // DeepLink sorununu önlemek için ayar ekliyoruz
        forceResendingToken: null,
      );
    } catch (e) {
      debugPrint('Beklenmeyen hata: $e');

      if (!mounted || !_isActive) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  // SMS kodu doğrulama
  Future<void> _verifySmsCode() async {
    debugPrint('SMS kodu doğrulanıyor: ${_smsController.text}');

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

      // Kullanıcı var mı kontrol et
      if (_auth.currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Mevcut kullanıcıya phone number ekle (linkWithCredential tekrar deniyelim)
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
      debugPrint('SMS doğrulama hatası: $e');

      if (!mounted || !_isActive) return;

      setState(() {
        _isLoading = false;
      });

      // Hata FirebaseAuthException ve error code'u provider-already-linked ise
      // Telefon numarası zaten doğrulanmış demektir
      if (e is FirebaseAuthException && e.code == 'provider-already-linked') {
        // Firestore'da kullanıcı bilgilerini güncelle
        if (_auth.currentUser != null) {
          await _customerService.updateCustomerVerifiedAndPhone(_auth.currentUser!.uid, true, _formattedPhoneNumber);
          debugPrint('Telefon zaten doğrulanmış, Firestore bilgileri güncellendi');
        }

        // Kullanıcıya bilgi ver
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Telefon numarası zaten doğrulanmış')),
          );
          // Başarılı olduğunda önceki sayfaya dön
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Doğrulama kodu hatası: $e')),
          );
        }
      }
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

  // Doğrudan telefon doğrulama işlemini başlat
  void _directVerifyPhone() {
    debugPrint('Doğrudan telefon doğrulama başlatılıyor');

    // Telefon numarası boş mu kontrol et
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen telefon numarası girin')),
      );
      return;
    }

    _verifyPhoneNumber();
  }

  // Doğrudan SMS doğrulama işlemini başlat
  void _directVerifySms() {
    debugPrint('Doğrudan SMS doğrulama başlatılıyor');

    // SMS kodu boş mu kontrol et
    if (_smsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen doğrulama kodunu girin')),
      );
      return;
    }

    _verifySmsCode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telefon Doğrulama'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null // Yükleme sırasında butonu devre dışı bırak
                              : (_currentStep == 0
                                  ? _directVerifyPhone // Doğrudan doğrulama işlemini başlat
                                  : _directVerifySms), // Doğrudan SMS doğrulama işlemini başlat
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            _currentStep == 0 ? 'Kod Gönder' : 'Doğrula',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (_currentStep > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: TextButton(
                              onPressed: _isLoading ? null : details.onStepCancel,
                              child: const Text('Geri'),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                onStepContinue: () {
                  // Bu metot artık kullanılmıyor, doğrudan buton işlevleri kullanılıyor
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() {
                      _currentStep -= 1;
                    });
                  }
                },
                steps: [
                  Step(
                    title: const Text('Telefon Numarası'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefon Numarası',
                            hintText: '+90 5XX XXX XX XX',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: _validatePhoneNumber,
                          onChanged: (value) {
                            // Değişiklik olduğunda state'i güncelle
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Lütfen ülke kodu ile birlikte girin (örn: +90 5XX XXX XX XX)',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (_isLoading && _currentStep == 0)
                          const Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        // iOS için reCAPTCHA içeriği
                        if (Platform.isIOS)
                          Container(
                            key: _recaptchaKey,
                            margin: const EdgeInsets.only(top: 16),
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[50],
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.security, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(
                                    'iOS için CAPTCHA Doğrulama',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Hata durumunda ipucu ekleyelim
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📝 Bilgi:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'SMS kodunun gelmesi biraz zaman alabilir. Lütfen en az 2 dakika bekleyin.',
                                style: TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              if (Platform.isIOS) ...[
                                const Text(
                                  'iOS\'ta doğrulama işlemi için Apple güvenlik protokollerine uygun CAPTCHA doğrulaması gerekebilir.',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                ),
                                const SizedBox(height: 4),
                              ],
                              const Text(
                                'Kod gelmediyse numaranızı kontrol edip tekrar deneyin.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: const Text('Doğrulama Kodu'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _smsController,
                          decoration: const InputDecoration(
                            labelText: 'Doğrulama Kodu',
                            hintText: '6 haneli kod',
                            prefixIcon: Icon(Icons.sms),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Telefonunuza gönderilen 6 haneli kodu girin',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (_isLoading && _currentStep == 1)
                          const Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                    isActive: _currentStep >= 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
