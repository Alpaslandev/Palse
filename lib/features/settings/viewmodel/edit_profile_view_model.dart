import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:intl/intl.dart';

class EditProfileViewModel extends ChangeNotifier {
  Customer user;
  final CustomerService customerService;
  bool isLoading = false;

  // Text Controllers
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  EditProfileViewModel({required this.user, required this.customerService}) {
    _initializeControllers();
  }

  void _initializeControllers() {
    nicknameController.text = '@${user.nickname}';
    nameController.text = user.firstName ?? '';
    lastNameController.text = user.lastName ?? '';
    phoneController.text = user.phoneNumber ?? '';
    addressController.text = '${user.district}, ${user.city}';
    birthDateController.text = user.birthday != null ? DateFormat('dd/MM/yyyy').format(user.birthday!) : '';
    genderController.text = user.gender?.name ?? '';

    // Controller'ların değişikliklerini dinle
    nicknameController.addListener(() => updateNickname(nicknameController.text.replaceAll('@', '')));
    nameController.addListener(() => updateName(nameController.text));
    lastNameController.addListener(() => updateLastName(lastNameController.text));
    phoneController.addListener(() => updatePhoneNumber(phoneController.text));
  }

  @override
  void dispose() {
    nicknameController.dispose();
    nameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    birthDateController.dispose();
    genderController.dispose();
    super.dispose();
  }

  void updateNickname(String nickname) {
    debugPrint('Updating nickname to: $nickname');
    user.nickname = nickname;
    notifyListeners();
  }

  void updateName(String name) {
    debugPrint('Updating name to: $name');
    debugPrint('Before update - firstName: ${user.firstName}');
    user.firstName = name;
    debugPrint('After update - firstName: ${user.firstName}');
    notifyListeners();
  }

  void updateLastName(String lastName) {
    debugPrint('Updating lastName to: $lastName');
    debugPrint('Before update - lastName: ${user.lastName}');
    user.lastName = lastName;
    debugPrint('After update - lastName: ${user.lastName}');
    notifyListeners();
  }

  void updatePhoneNumber(String phoneNumber) {
    debugPrint('Updating phoneNumber to: $phoneNumber');
    user.phoneNumber = phoneNumber;
    notifyListeners();
  }

  void updateCity(String city) {
    debugPrint('Updating city to: $city');
    user.city = city;
    addressController.text = '${user.district}, $city';
    notifyListeners();
  }

  void updateDistrict(String district) {
    debugPrint('Updating district to: $district');
    user.district = district;
    addressController.text = '$district, ${user.city}';
    notifyListeners();
  }

  void updateGeoPoint(double latitude, double longitude) {
    debugPrint('Updating geoPoint to: lat=$latitude, lon=$longitude');
    user.geoPoint = GeoPoint(latitude, longitude);
    notifyListeners();
  }

  Future<void> updateProfil() async {
    try {
      isLoading = true;
      notifyListeners();
      debugPrint('Updating profile with firstName: ${user.firstName}, lastName: ${user.lastName}');
      debugPrint('Full user data: ${user.toJson()}');
      await customerService.updateCustomer(user.userID!, user);
    } catch (e) {
      debugPrint('Error updating profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
