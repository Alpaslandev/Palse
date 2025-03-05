import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';

class FriendProfileViewModel extends ChangeNotifier {
  final AdvertService advertService = AdvertService();
  final CustomerService customerService = CustomerService();
  final String customerID;
  Customer? customer;
  List<Advert> adverts = [];
  bool isLoading = false;

  FriendProfileViewModel({required this.customerID}) {
    getCustomer();
  }

  Future<void> getCustomer() async {
    isLoading = true;
    notifyListeners();
    try {
      customer = await customerService.fetchUserFromFirestore(customerID);
      debugPrint('Kullanıcı bilgileri yüklendi: ${customer?.firstName}');
      await getAdverts();
      debugPrint('İlanlar yüklendi: ${adverts.length}');
    } catch (e) {
      debugPrint('Kullanıcı bilgileri yüklenirken hata: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getAdverts() async {
    adverts.clear();
    if (customer?.adverts == null || customer?.adverts!.isEmpty == true) {
      debugPrint('Kullanıcının ilanı bulunmuyor');
      return;
    }
    for (var eventId in customer?.adverts ?? []) {
      debugPrint('İlan yükleniyor: $eventId');
      final advert = await advertService.fetchAdvertById(eventId);
      if (advert != null) {
        adverts.add(advert);
        debugPrint('İlan eklendi: ${advert.advertName}');
      }
    }
  }
}
