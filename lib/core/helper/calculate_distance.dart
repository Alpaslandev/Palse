// İki konum arasındaki mesafeyi kilometre cinsinden hesaplar
import 'dart:math';

String calculateDistance({required double latitude1, required double longitude1, required double latitude2, required double longitude2}) {
  const int earthRadius = 6371000; // Dünya yarıçapı (metre)

  double lat1 = latitude1 * (pi / 180);
  double lon1 = longitude1 * (pi / 180);
  double lat2 = latitude2 * (pi / 180);
  double lon2 = longitude2 * (pi / 180);

  double dLat = lat2 - lat1;
  double dLon = lon2 - lon1;

  double a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  final distance = (earthRadius * c / 1000).ceil();

  final distanceString = "$distance km";

  return distanceString; // Direkt olarak km cinsinden sonuç
}
