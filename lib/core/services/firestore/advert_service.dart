import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';

class AdvertService {
  Future<List<Advert>?> fetchAdvertsFromFirestore() async {
    try {
      // Fetch all documents from the 'adverts' collection
      QuerySnapshot advertsSnapshot = await FirebaseFirestore.instance.collection('adverts').orderBy('createdAt', descending: true).get();

      // List to store all adverts from the 'adverts' collection
      List<Advert> allAdverts = [];
      // Get current date
      String currentDate = DateTime.now().toLocal().toString().split(' ')[0];

      // Iterate over each document in the 'adverts' collection
      for (var advertsDoc in advertsSnapshot.docs) {
        // Map Firestore data to an Advert object
        Advert advert = Advert.fromJson(advertsDoc.data() as Map<String, dynamic>);
        String? lastUsageString = advert.advertLastUsage;
        List<String> dateParts = lastUsageString.split('/');
        int day = int.parse(dateParts[0]);
        int month = int.parse(dateParts[1]);
        int year = int.parse(dateParts[2]);
        DateTime lastUsage = DateTime(year, month, day);

        if (lastUsage.isAfter(DateTime.parse(currentDate)) || lastUsage.isAtSameMomentAs(DateTime.parse(currentDate))) {
          allAdverts.add(advert);
        }
      }

      return allAdverts;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<GeoPoint?> fetchAdvertGeoPoint(String advertID) async {
    try {
      // Get the advert document from the adverts collection
      DocumentSnapshot advertSnapshot = await FirebaseFirestore.instance.collection('adverts').doc(advertID).get();

      // Retrieve the geoPoint field from the advert document
      Map<String, dynamic>? geoPointData = advertSnapshot['geoPoint'];

      // Convert Map<String, dynamic> to GeoPoint
      if (geoPointData != null) {
        double latitude = geoPointData['latitude'];
        double longitude = geoPointData['longitude'];
        GeoPoint advertGeoPoint = GeoPoint(latitude, longitude);
        debugPrint('Advert Latitude: $latitude, Longitude: $longitude');
        return advertGeoPoint;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error retrieving advert data: $e');
      return null;
    }
  }
}
