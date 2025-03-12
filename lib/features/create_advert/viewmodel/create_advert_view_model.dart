import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palseapp/core/constant/categories.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/models/location_model.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:palseapp/features/achievement/achievement_service.dart';
import 'package:palseapp/features/achievement/xp_events.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';

class CreateAdvertViewModel extends ChangeNotifier {
  final LocationService locationService;
  final AuthProvider authProvider;
  final formKey = GlobalKey<FormState>();
  final locationController = TextEditingController();
  // Form değerleri
  String advertName = '';
  String advertDescription = '';
  File? advertImage;
  String address = '';
  String country = '';
  String city = '';
  String district = '';
  DateTime? startDate;
  DateTime? endDate;
  Categories? eventType;
  bool _isLoading = false;
  LocationModel? locationModel;

  bool get isLoading => _isLoading;
  int currentStep = 0;

  CreateAdvertViewModel({
    required this.authProvider,
    required this.locationService,
  });

  // Stepper kontrolleri
  void onStepContinue() {
    if (currentStep < 2) {
      if (currentStep == 0 && !formKey.currentState!.validate()) return;
      currentStep++;
      notifyListeners();
    }
  }

  void onStepCancel() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  // Resim seçimi
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      advertImage = File(image.path);
      notifyListeners();
    }
  }

  void setAdvertImage(File image) {
    advertImage = image;
    notifyListeners();
  }

  void updateLocation(LocationModel location) {
    debugPrint('UpdateLocation çağrıldı');
    debugPrint('Gelen LocationModel: ${location.toString()}');
    debugPrint('Konum Detayları - Şehir: ${location.city}, İlçe: ${location.district}, Ülke: ${location.country}');
    debugPrint('Koordinatlar - Lat: ${location.lat}, Lon: ${location.lon}');

    city = location.city;
    district = location.district;
    country = location.country;
    address = location.displayString();
    locationModel = location;
    locationController.text = location.displayString();

    debugPrint('Değerler güncellendi - Şehir: $city, İlçe: $district');
    notifyListeners();
  }

  // İlan oluşturma
  Future<void> createAdvert() async {
    _setLoading(true);
    try {
      final advert = Advert(
        title: advertName,
        description: advertDescription,
        creatorUserID: authProvider.user!.userID!,
        advertType: eventType ?? Categories.diger,
        location: locationModel!,
        advertImage: advertImage?.path ?? '',
        startEventDate: startDate ?? DateTime.now(),
        createdAt: DateTime.now(),
        likers: [],
        creatorGender: authProvider.user!.gender ?? Gender.male,
      );

      debugPrint('Advert: ${advert.toJson()}');
      // Yeni kampanyayı Firestore koleksiyonuna ekle ve döküman ID'sini al
      DocumentReference docRef = await FirebaseFirestore.instance.collection('events').add(advert.toJson());
      // Müşteri koleksiyonunu güncelle
      await FirebaseFirestore.instance.collection('customers').doc(authProvider.user!.userID).update({
        'adverts': FieldValue.arrayUnion([docRef.id]), // Döküman ID'sini kullan
      });
      // İlan oluşturma işleminde
      final achievementService = AchievementService();
      final earnedXp = await achievementService.handleListingCreation(authProvider.user!.userID!);
      // XP kazanıldığında bildirim gösterme
      if (earnedXp > 0) {
        ScaffoldMess.showSuccessSnackBar("Tebrikler! İlan oluşturarak $earnedXp XP kazandınız.");
      }
    } catch (e) {
      debugPrint('Error creating advert: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Yardımcı metodlar
  bool validateAllFields() {
    if (advertName.isEmpty || advertDescription.isEmpty) return false;
    if (advertImage == null) return false;
    if (locationModel == null) return false;
    if (startDate == null) return false;
    return true;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    startDate = date;
    notifyListeners();
  }

  void setEventType(Categories? value) {
    eventType = value;
    notifyListeners();
  }
}
