// Profil kurulum sürecini yöneten ViewModel
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';

class ProfileSetupViewModel extends ChangeNotifier {
  int _currentStep = 0;
  final Customer _customer = Customer();

  int get currentStep => _currentStep;
  Customer get customer => _customer;

  void nextStep() {
    if (_currentStep < 4) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
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
}
