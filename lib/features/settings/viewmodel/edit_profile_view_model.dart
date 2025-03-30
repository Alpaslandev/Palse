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
    user = user.copyWith(profilePictureUrl: url);
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

    // Konum alanını daha güvenli şekilde güncelle
    if (user.location != null) {
      addressController.text = user.location!.displayString();
    } else {
      addressController.text = '';
    }

    // Doğum tarihi alanını daha güvenli şekilde güncelle
    if (user.birthday != null) {
      birthDateController.text = DateFormat('dd/MM/yyyy').format(user.birthday!);
    } else {
      birthDateController.text = '';
    }

    // Cinsiyet alanını daha güvenli şekilde güncelle
    genderController.text = user.gender?.textKey ?? '';
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
    user = user.copyWith(nickname: nickname);
    notifyListeners();
  }

  Future<void> updatePhone(String phone, bool verified) async {
    await customerService.updateCustomerVerifiedAndPhone(user.userID!, verified, phone);
    user = user.copyWith(phoneNumber: phone, verification: verified);
    notifyListeners();
  }

  void updateName(String name) {
    debugPrint('Updating name to: $name');
    debugPrint('Before update - firstName: ${user.firstName}');
    user = user.copyWith(firstName: name);
    debugPrint('After update - firstName: ${user.firstName}');
    notifyListeners();
  }

  void updateLastName(String lastName) {
    debugPrint('Updating lastName to: $lastName');
    debugPrint('Before update - lastName: ${user.lastName}');
    user = user.copyWith(lastName: lastName);
    debugPrint('After update - lastName: ${user.lastName}');
    notifyListeners();
  }

  void updateLocation(LocationModel location) {
    debugPrint(
        'Updating location - country: ${location.country}, city: ${location.city}, district: ${location.district}, lat: ${location.lat}, lon: ${location.lon}');

    // copyWith metodunu kullanarak mevcut değerleri koruyan daha güvenli bir güncelleme yapalım
    user = user.copyWith(location: location);

    // Controller'ları güncelle
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
        // copyWith metodunu kullanarak tüm değerleri daha güvenli bir şekilde güncelleyelim
        // Mevcut kullanıcıdan gelen değerler kullanıcının değiştirmediği alanlar için kullanılır
        final updatedUser = currentUser.copyWith(
          firstName: user.firstName,
          lastName: user.lastName,
          nickname: user.nickname,
          phoneNumber: user.phoneNumber,
          verification: user.verification,
          profilePictureUrl: user.profilePictureUrl,
          location: user.location,
        );

        debugPrint('Güncellenen profil verileri: ${updatedUser.toJson()}');
        await customerService.updateCustomer(user.userID!, updatedUser);

        // Güncellenmiş kullanıcıyı mevcut kullanıcı olarak atayalım
        user = updatedUser;

        // Controller'ları güncelle
        _updateControllersFromUser();
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
