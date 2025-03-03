// Profil kurulum sürecini yöneten ViewModel
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _profilePictureUrlController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  XFile? selectedImage;

  final CloudStorageService _storageService = CloudStorageService();
  final CustomerService _customerService = CustomerService();

  // AuthProvider'ı tanımlayıp, yapıcıda gerekli atamayı yapıyoruz
  final AuthProvider _authProvider;

  ProfileSetupViewModel({required AuthProvider authProvider}) : _authProvider = authProvider;

  int get currentStep => _currentStep; // Mevcut adımı döndürür
  Customer get customer => _customer; // Müşteri bilgilerini döndürür
  PageController get pageController => _pageController; // Sayfa kontrolcüsünü döndürür
  bool get isLastStep => _currentStep == 5;

  TextEditingController get firstNameController => _firstNameController;
  TextEditingController get lastNameController => _lastNameController;
  TextEditingController get nicknameController => _nicknameController;
  TextEditingController get cityController => _cityController;
  TextEditingController get districtController => _districtController;
  TextEditingController get profilePictureUrlController => _profilePictureUrlController;
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

  Future<bool> completeProfileSetup() async {
    debugPrint('Profile setup completed');

    debugPrint(_authProvider.firebaseUser?.uid ?? 'User ID not found');

    debugPrint(_customer.toJson().toString());
    debugPrint(_customer.location?.geoPoint?.latitude.toString() ?? 'GeoPoint not found');
    debugPrint(_customer.location?.geoPoint?.longitude.toString() ?? 'GeoPoint not found');

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
      await _customerService.updateCustomer(_authProvider.firebaseUser!.uid, _customer);
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

  void handleCategorySelection(String category, bool selected) {
    final categories = List<String>.from(_customer.favoriteCategories ?? []);
    if (selected) {
      categories.add(category);
    } else {
      categories.remove(category);
    }
    _customer.favoriteCategories = categories;
    notifyListeners();
  }

  void updateCoordinates(double lat, double lon) {
    _customer.location = LocationModel(lat: lat, lon: lon, city: '', district: '', country: '');
    notifyListeners();
  }

  void updateFirstName(String firstName) {
    _customer.firstName = firstName;
    notifyListeners();
  }

  void updateLastName(String lastName) {
    _customer.lastName = lastName;
    notifyListeners();
  }

  void updateNickname(String nickname) {
    _customer.nickname = nickname;
    notifyListeners();
  }

  void pickImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 60, // 0-100 arası kalite
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
}
