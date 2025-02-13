import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';

class EditProfileViewModel extends ChangeNotifier {
  final Customer user;
  final CustomerService customerService;
  bool isLoading = false;

  EditProfileViewModel({required this.user, required this.customerService});

  void updateNickname(String nickname) {
    user.copyWith(nickname: nickname);
    notifyListeners();
  }

  void updateName(String name) {
    user.copyWith(firstName: name);
    notifyListeners();
  }

  void updateLastName(String lastName) {
    user.copyWith(lastName: lastName);
    notifyListeners();
  }

  void updatePhoneNumber(String phoneNumber) {
    user.copyWith(phoneNumber: phoneNumber);
    notifyListeners();
  }

  void updateCity(String city) {
    user.copyWith(city: city);
    notifyListeners();
  }

  void updateDistrict(String district) {
    user.copyWith(district: district);
    notifyListeners();
  }

  void updateGeoPoint(double latitude, double longitude) {
    user.copyWith(geoPoint: GeoPoint(latitude, longitude));
    notifyListeners();
  }

  Future<void> updateProfilePicture(String profilePictureUrl) async {
    user.copyWith(profilePictureUrl: profilePictureUrl);
    await FirebaseFirestore.instance.collection('users').doc(user.userID).update({'profilePictureUrl': profilePictureUrl});
    notifyListeners();
  }

  Future<void> updateProfil() async {
    try {
      isLoading = true;
      await customerService.updateCustomer(user.userID!, user);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
