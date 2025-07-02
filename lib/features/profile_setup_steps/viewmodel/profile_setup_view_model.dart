// Profil kurulum sürecini yöneten ViewModel
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/cloud_storage.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';

class ProfileSetupViewModel extends ChangeNotifier {
  int _currentStep = 0;
  final Customer _customer = Customer();
  final PageController _pageController = PageController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _profilePictureUrlController =
      TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  XFile? selectedImage;

  final CloudStorageService _storageService = CloudStorageService();
  final CustomerService _customerService = CustomerService();

  // AuthProvider'ı tanımlayıp, yapıcıda gerekli atamayı yapıyoruz
  final AuthProvider _authProvider;

  ProfileSetupViewModel({required AuthProvider authProvider})
      : _authProvider = authProvider;

  int get currentStep => _currentStep; // Mevcut adımı döndürür
  Customer get customer => _customer; // Müşteri bilgilerini döndürür
  PageController get pageController =>
      _pageController; // Sayfa kontrolcüsünü döndürür
  bool get isLastStep => _currentStep == 5;

  LocationModel? _location;
  LocationModel? get location => _location;

  bool get isLoading => _authProvider.isLoading;

  TextEditingController get firstNameController => _firstNameController;
  TextEditingController get nicknameController => _nicknameController;
  TextEditingController get cityController => _cityController;
  TextEditingController get districtController => _districtController;
  TextEditingController get profilePictureUrlController =>
      _profilePictureUrlController;
  TextEditingController get birthdayController => _birthdayController;
  TextEditingController get genderController => _genderController;

  void nextStep() {
    if (_currentStep < 6) {
      _currentStep++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  Future<bool> completeProfileSetup(String locale) async {
    debugPrint('Profile setup completed');

    debugPrint(_authProvider.firebaseUser?.uid ?? 'User ID not found');

    debugPrint(_customer.toJson().toString());
    debugPrint(_customer.location?.geoPoint?.latitude.toString() ??
        'GeoPoint not found');
    debugPrint(_customer.location?.geoPoint?.longitude.toString() ??
        'GeoPoint not found');

    String? storageUrl;

    try {
      if (selectedImage != null) {
        storageUrl = await _storageService.uploadUserFile(
            userId: _authProvider.firebaseUser!.uid,
            fileType: FileType.profile,
            fileName: DateTime.now().millisecondsSinceEpoch.toString(),
            file: File(selectedImage!.path));
        _customer.profilePictureUrl = storageUrl;
        debugPrint(storageUrl);
      }

      _customer.userID = _authProvider.firebaseUser!.uid;
      _customer.languagePreference = locale;
      await _customerService.updateCustomer(
          _authProvider.firebaseUser!.uid, _customer);
      debugPrint('Profile setup completed');
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    } finally {
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }

  void handleCategorySelection(Categories category, bool selected) {
    final categories =
        List<Categories>.from(_customer.favoriteCategories ?? []);
    if (selected) {
      categories.add(category);
    } else {
      categories.remove(category);
    }
    _customer.favoriteCategories = categories;
    notifyListeners();
  }

  void updateCoordinates(LocationModel location) {
    _location = location;
    _customer.location = location;
    notifyListeners();
  }

  void updateFirstName(String firstName) {
    _customer.firstName = firstName;
    notifyListeners();
  }

  // Ad için validasyon metodu
  bool isFirstNameValid() {
    return _customer.firstName != null &&
        _customer.firstName!.isNotEmpty &&
        _customer.firstName!.length >= 3;
  }

  // Kullanıcı bilgileri adımının validasyonu
  bool isUserInfoStepValid() {
    return isFirstNameValid();
  }

  void updateNickname(String nickname) {
    _customer.nickname = nickname;
    notifyListeners();
  }

  void pickImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // 0-100 arası kalite
        maxWidth: 800, // maksimum genişlik
        maxHeight: 800, // maksimum yükseklik
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        selectedImage = image;
      }
    } catch (e) {
      debugPrint('Görsel seçme hatası: $e');
    } finally {
      notifyListeners();
    }
  }

  void updateBirthDate(DateTime date) {
    _customer.birthday = date;
    notifyListeners();
  }

  void updateGender(Gender gender) {
    _customer.gender = gender;
    notifyListeners();
  }

  // Doğum tarihi için validasyon metodu
  bool isBirthdayValid() {
    return true; // Doğum tarihi opsiyonel olduğu için her zaman geçerli
  }

  // Cinsiyet için validasyon metodu
  bool isGenderValid() {
    return true; // Cinsiyet opsiyonel olduğu için her zaman geçerli
  }

  // Doğum tarihi ve cinsiyet adımının validasyonu
  bool isBirthdayGenderStepValid() {
    return true; // Artık her zaman geçerli
  }

  void updateLocation(LocationModel location) {
    _customer.location = location;
    notifyListeners();
  }

  // Konum için validasyon metodu
  bool isLocationValid() {
    return true; // Konum opsiyonel olduğu için her zaman geçerli
  }

  // Konum adımının validasyonu
  bool isLocationStepValid() {
    return true; // Artık her zaman geçerli
  }

  // Takma ad için validasyon metodu
  bool isNicknameValid() {
    return _customer.nickname != null &&
        _customer.nickname!.isNotEmpty &&
        _customer.nickname!.length >= 3;
  }

  // Takma ad adımının validasyonu
  bool isNicknameStepValid() {
    return isNicknameValid();
  }

  // Favori kategoriler için validasyon metodu
  bool areFavoriteCategoriesValid() {
    return _customer.favoriteCategories != null &&
        _customer.favoriteCategories!.length >= 3;
  }

  // Favori kategoriler adımının validasyonu
  bool isFavoriteCategoryStepValid() {
    return areFavoriteCategoriesValid();
  }
}
