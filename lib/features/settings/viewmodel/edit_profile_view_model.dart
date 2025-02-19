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
    _updateControllersFromUser();

    // Controller'ların değişikliklerini dinle
    nicknameController.addListener(() => updateNickname(nicknameController.text.replaceAll('@', '')));
    nameController.addListener(() => updateName(nameController.text));
    lastNameController.addListener(() => updateLastName(lastNameController.text));
    phoneController.addListener(() => updatePhoneNumber(phoneController.text));
  }

  void _updateControllersFromUser() {
    nicknameController.text = '@${user.nickname ?? ''}';
    nameController.text = user.firstName ?? '';
    lastNameController.text = user.lastName ?? '';
    phoneController.text = user.phoneNumber ?? '';
    addressController.text = '${user.district ?? ''}, ${user.city ?? ''}'.replaceAll(', ,', ',').trim().replaceAll(RegExp(r'^,|,$'), '');
    birthDateController.text = user.birthday != null ? DateFormat('dd/MM/yyyy').format(user.birthday!) : '';
    genderController.text = user.gender?.name ?? '';
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
    _updateAddressText();
    notifyListeners();
  }

  void updateDistrict(String district) {
    debugPrint('Updating district to: $district');
    user.district = district;
    _updateAddressText();
    notifyListeners();
  }

  void updateCountry(String country) {
    debugPrint('Updating country to: $country');
    user.country = country;
    notifyListeners();
  }

  void _updateAddressText() {
    final district = user.district ?? '';
    final city = user.city ?? '';
    if (district.isNotEmpty || city.isNotEmpty) {
      addressController.text = '$district, $city';
    }
  }

  void updateLocation({String? country, String? city, String? district, double? latitude, double? longitude}) {
    debugPrint('Updating location - country: $country, city: $city, district: $district, lat: $latitude, lon: $longitude');

    // Mevcut değerleri koru
    final updatedUser = Customer(
      userID: user.userID,
      firstName: user.firstName,
      lastName: user.lastName,
      nickname: user.nickname,
      phoneNumber: user.phoneNumber,
      email: user.email,
      birthday: user.birthday,
      gender: user.gender,
      verification: user.verification,
      isPremium: user.isPremium,
      profilePictureUrl: user.profilePictureUrl,
      favoriteCategories: user.favoriteCategories,
      events: user.events,
      blockUsers: user.blockUsers,
      favoriteAdverts: user.favoriteAdverts,
      chatInfos: user.chatInfos,
      // Yeni konum bilgilerini güncelle
      country: country ?? user.country,
      city: city ?? user.city,
      district: district ?? user.district,
      geoPoint: latitude != null && longitude != null ? GeoPoint(latitude, longitude) : user.geoPoint,
    );

    user = updatedUser;
    _updateControllersFromUser();
    notifyListeners();
  }

  void updateCoordinates(double lat, double lon) {
    debugPrint('Updating coordinates: lat=$lat, lon=$lon');
    user.geoPoint = GeoPoint(lat, lon);
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
