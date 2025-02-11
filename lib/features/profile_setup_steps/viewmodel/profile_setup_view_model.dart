// Profil kurulum sürecini yöneten ViewModel
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';

class ProfileSetupViewModel extends ChangeNotifier {
  int _currentStep = 0;
  final Customer _customer = Customer();
  final PageController _pageController = PageController();
  int get currentStep => _currentStep;
  Customer get customer => _customer;
  PageController get pageController => _pageController;

  void nextStep() {
    if (_currentStep < 5 && _validateCurrentStep()) {
      _currentStep++;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _customer.firstName != null && _customer.lastName != null;
      case 1:
        return _customer.nickname != null;
      case 2:
        return _customer.city != null && _customer.district != null;
      default:
        return true;
    }
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

  void updateCity(String city) {
    _customer.city = city;
    notifyListeners();
  }

  void updateDistrict(String district) {
    _customer.district = district;
    notifyListeners();
  }

  void updateProfileImage(String imagePath) {
    _customer.profilePictureUrl = imagePath;
    notifyListeners();
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
