// İki konum arasındaki mesafeyi kilometre cinsinden hesaplar
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

String calculateDistance(GeoPoint customerLocation, GeoPoint advertLocation) {
  const int earthRadius = 6371000; // Dünya yarıçapı (metre)

  double lat1 = customerLocation.latitude * (pi / 180);
  double lon1 = customerLocation.longitude * (pi / 180);
  double lat2 = advertLocation.latitude * (pi / 180);
  double lon2 = advertLocation.longitude * (pi / 180);

  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;

  double a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  final distance = (earthRadius * c / 1000).ceil();

  final distanceString = "$distance km";

  return distanceString; // Direkt olarak km cinsinden sonuç
}
