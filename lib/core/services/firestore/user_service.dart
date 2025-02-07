import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:palseapp/core/models/customer.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Customer?> getCurrentUser(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDocument = await _firestore.collection("usersCollection").doc(uid).get();
    if (userDocument.data() != null && userDocument.exists) {
      return Customer.fromJson(userDocument.data()!);
    } else {
      return null;
    }
  }

  Future<void> updateUserCoin(Customer user) async {
    await _firestore.collection("usersCollection").doc(user.userID).update({
      'coins': user.coins,
    });
  }

  Future<void> deleteUser(String userID) async {
    try {
      FirebaseAuth.instance.currentUser?.delete();
      _firestore.collection("usersCollection").doc(userID).delete();
    } catch (e) {
      throw 'Failed to delete user. $e';
    }
  }

  Future<GeoPoint?> fetchCustomerGeoPoint(String customerID) async {
    try {
      // Get the customer document from the customers collection
      DocumentSnapshot customerSnapshot = await FirebaseFirestore.instance.collection('customers').doc(customerID).get();

      // Retrieve the geoPoint field from the customer document
      GeoPoint? customerGeoPoint = customerSnapshot['geoPoint'];

      // Return the GeoPoint
      if (customerGeoPoint != null) {
        debugPrint('Customer Latitude: ${customerGeoPoint.latitude}, Longitude: ${customerGeoPoint.longitude}');
        return customerGeoPoint;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error retrieving customer data: $e');
      return null;
    }
  }
}
