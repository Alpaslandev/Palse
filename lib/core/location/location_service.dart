import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Konum servis sınıfı
/// Bu sınıf, konum izinlerini yönetmek ve konum bilgilerini almak için kullanılır
class LocationService {
  /// Konum izinlerini kontrol eder ve gerekirse kullanıcıdan izin ister
  ///
  /// [BuildContext] context: İzin isteği sırasında dialog göstermek için kullanılır
  ///
  /// Dönüş değeri: Konum izni verildi mi?
  static Future<bool> checkAndRequestPermission(BuildContext context) async {
    // Konum servisinin açık olup olmadığını kontrol et
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Konum servisi kapalıysa kullanıcıya bilgi ver
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Konum Servisi Kapalı'),
              content: const Text('Konum özelliklerini kullanabilmek için lütfen cihazınızın konum servisini açın.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Tamam'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return false;
    }

    // Konum izinlerini kontrol et
    LocationPermission permission = await Geolocator.checkPermission();

    // İzin henüz istenmemişse, izin iste
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Kullanıcı izin vermeyi reddettiyse bilgi ver
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Konum İzni Reddedildi'),
                content: const Text('Konum özelliklerini kullanabilmek için konum izni vermeniz gerekmektedir.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Tamam'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
        return false;
      }
    }

    // Kullanıcı izin vermeyi kalıcı olarak reddettiyse, ayarlara yönlendir
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Konum İzni Kalıcı Olarak Reddedildi'),
              content: const Text('Konum özelliklerini kullanabilmek için uygulama ayarlarından konum iznini etkinleştirmeniz gerekmektedir.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Ayarlara Git'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Geolocator.openAppSettings();
                  },
                ),
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return false;
    }

    // İzin verildi
    return true;
  }

  /// Mevcut konumu alır
  ///
  /// Dönüş değeri: [Position] nesnesi
  static Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
      return null;
    }
  }

  /// Konum bilgisinden adres bilgisini alır
  ///
  /// [Position] position: Konum bilgisi
  ///
  /// Dönüş değeri: Adres bilgisi
  static Future<String?> getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.country}';
      }
      return null;
    } catch (e) {
      debugPrint('Adres bilgisi alınamadı: $e');
      return null;
    }
  }
}
