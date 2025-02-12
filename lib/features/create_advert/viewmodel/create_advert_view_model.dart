import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAdvertViewModel extends ChangeNotifier {
  final LocationService locationService;
  final AuthProvider authProvider;
  final formKey = GlobalKey<FormState>();

  // Form değerleri
  String advertName = '';
  String advertDescription = '';
  XFile? advertImage;
  LatLng? selectedLocation;
  String address = '';
  String country = '';
  String city = '';
  String district = '';
  DateTime? startDate;
  DateTime? endDate;
  String? eventType;
  bool _isLoading = false;
  GeoPoint? geoPoint;

  bool get isLoading => _isLoading;
  int currentStep = 0;

  CreateAdvertViewModel({
    required this.authProvider,
    required this.locationService,
  });

  // Konum işlemleri
  Future<void> getCurrentLocation() async {
    try {
      _setLoading(true);
      selectedLocation = await locationService.getCurrentPosition();
      final GeoPoint geoPoint = GeoPoint(selectedLocation!.latitude, selectedLocation!.longitude);

      if (selectedLocation != null) {
        final addressInfo = await locationService.getAddressFromCoordinates(
          geoPoint,
        );

        address = addressInfo?.thoroughfare ?? '';
        city = addressInfo?.administrativeArea ?? '';
        district = addressInfo?.subAdministrativeArea ?? '';
        country = addressInfo?.country ?? '';
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> updateSelectedLocation(LatLng location) async {
    try {
      _setLoading(true);
      selectedLocation = location;
      await _updateLocationDetails();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _updateLocationDetails() async {
    if (selectedLocation == null) return;

    final addressInfo = await locationService.getAddressFromCoordinates(
      geoPoint!,
    );

    city = addressInfo?.administrativeArea ?? '';
    district = addressInfo?.subAdministrativeArea ?? '';
    country = addressInfo?.country ?? '';
    notifyListeners();
  }

  // Stepper kontrolleri
  void onStepContinue() {
    if (currentStep < 2) {
      if (currentStep == 0 && !formKey.currentState!.validate()) return;
      currentStep++;
      notifyListeners();
    } else {
      createAdvert();
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
      advertImage = image;
      notifyListeners();
    }
  }

  // İlan oluşturma
  Future<void> createAdvert() async {
    //  if (!validateAllFields()) return;

    _setLoading(true);
    try {
      // Konum bilgisini GeoPoint'e çevir
      geoPoint = await locationService.getGeoPoint(city, district, country);
      debugPrint('GeoPoint: ${geoPoint?.latitude} ${geoPoint?.longitude}');

      final advert = Advert(
        advertName: advertName,
        description: advertDescription,
        creatorUserID: authProvider.user!.userID!,
        advertType: eventType ?? '',
        geoPoint: geoPoint,
        country: country,
        city: city,
        district: district,
        advertImage: advertImage?.path ?? '',
        startEventDate: startDate ?? DateTime.now(),
        //  endEventDate: endDate ?? DateTime.now(),
        createdAt: DateTime.now(),
        countUUIDs: [],
      );

      debugPrint('Advert: ${advert.toJson()}');
      // Yeni kampanyayı Firestore koleksiyonuna ekle ve döküman ID'sini al
      DocumentReference docRef = await FirebaseFirestore.instance.collection('events').add(advert.toJson());
      // Müşteri koleksiyonunu güncelle
      await FirebaseFirestore.instance.collection('customers').doc(authProvider.user!.userID).update({
        'adverts': FieldValue.arrayUnion([docRef.id]), // Döküman ID'sini kullan
      });
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
    if (geoPoint == null) return false;
    if (startDate == null || endDate == null) return false;
    if (eventType == null) return false;
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

  void setEndDate(DateTime date) {
    endDate = date;
    notifyListeners();
  }

  void setEventType(String? value) {
    eventType = value;
    notifyListeners();
  }
}
