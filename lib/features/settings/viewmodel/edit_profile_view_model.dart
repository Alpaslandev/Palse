import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:intl/intl.dart';

class EditProfileViewModel extends ChangeNotifier {
  Customer user;
  final CustomerService customerService;
  bool isLoading = false;
  XFile? selectedImage;
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

  // Yükleme durumunu ayarlamak için fonksiyon
  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  // Profil fotoğrafı URL'ini güncelleyen fonksiyon
  void updateProfilePictureUrl(String url) {
    user.profilePictureUrl = url;
    notifyListeners();
  }

  Future<void> pickImage() async {
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

  void _initializeControllers() {
    _updateControllersFromUser();

    // Controller'ların değişikliklerini dinle
    nicknameController.addListener(() => updateNickname(nicknameController.text.replaceAll('@', '')));
    nameController.addListener(() => updateName(nameController.text));
    lastNameController.addListener(() => updateLastName(lastNameController.text));
    phoneController.addListener(() => updatePhone(phoneController.text, user.verification!));
  }

  void _updateControllersFromUser() {
    nicknameController.text = '@ ${user.nickname ?? ''}';
    nameController.text = user.firstName ?? '';
    lastNameController.text = user.lastName ?? '';
    phoneController.text = user.phoneNumber ?? '';
    addressController.text = user.location?.displayString() ?? '';
    '${user.location?.district ?? ''}, ${user.location?.city ?? ''}'.replaceAll(', ,', ',').trim().replaceAll(RegExp(r'^,|,$'), '');
    birthDateController.text = user.birthday != null ? DateFormat('dd/MM/yyyy').format(user.birthday!) : '';
    genderController.text = user.gender?.trName ?? '';
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

  Future<void> updatePhone(String phone, bool verified) async {
    await customerService.updateCustomerVerifiedAndPhone(user.userID!, verified, phone);
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

  void updateLocation(LocationModel location) {
    debugPrint(
        'Updating location - country: ${location.country}, city: ${location.city}, district: ${location.district}, lat: ${location.lat}, lon: ${location.lon}');

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
      adverts: user.adverts,
      blockUsers: user.blockUsers,
      favoriteAdverts: user.favoriteAdverts,
      chatMap: user.chatMap,
      location: location,
    );

    user = updatedUser;
    _updateControllersFromUser();
    notifyListeners();
  }

  Future<void> updateProfil() async {
    try {
      isLoading = true;
      notifyListeners();

      // Önce mevcut kullanıcı bilgilerini alalım
      final currentUser = await customerService.getCustomer(user.userID!);

      if (currentUser != null) {
        // Mevcut kullanıcı verilerini koruyalım
        final updatedUser = Customer(
          userID: user.userID,
          firstName: user.firstName,
          lastName: user.lastName,
          nickname: user.nickname,
          phoneNumber: user.phoneNumber,
          email: user.email ?? currentUser.email,
          birthday: user.birthday ?? currentUser.birthday,
          gender: user.gender ?? currentUser.gender,
          verification: user.verification,
          isPremium: user.isPremium ?? currentUser.isPremium,
          profilePictureUrl: user.profilePictureUrl,
          favoriteCategories: user.favoriteCategories ?? currentUser.favoriteCategories,
          adverts: user.adverts ?? currentUser.adverts,
          blockUsers: user.blockUsers ?? currentUser.blockUsers,
          favoriteAdverts: user.favoriteAdverts ?? currentUser.favoriteAdverts,
          chatMap: user.chatMap ?? currentUser.chatMap,
          location: user.location ?? currentUser.location,
        );

        debugPrint('Güncellenen profil verileri: ${updatedUser.toJson()}');
        await customerService.updateCustomer(user.userID!, updatedUser);
      } else {
        // Eğer mevcut kullanıcı yoksa, şu anki verileri kullan
        debugPrint('Mevcut kullanıcı bulunamadı. Şu anki veriler kullanılıyor.');
        debugPrint('Profil verileri: ${user.toJson()}');
        await customerService.updateCustomer(user.userID!, user);
      }
    } catch (e) {
      debugPrint('Profil güncelleme hatası: $e');
      throw Exception('Profil güncelleme hatası: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
