import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';

class FriendProfileViewModel extends ChangeNotifier {
  final AdvertService advertService = AdvertService();
  final Customer customer;
  List<Advert> adverts = [];
  bool isLoading = false;

  FriendProfileViewModel({required this.customer}) {
    getAdverts();
  }

  Future<void> getAdverts() async {
    isLoading = true;
    notifyListeners();
    try {
      adverts.clear();

      if (customer.events == null || customer.events!.isEmpty) {
        debugPrint('Kullanıcının ilanı bulunmuyor');
        return;
      }

      for (var eventId in customer.events ?? []) {
        debugPrint('İlan yükleniyor: $eventId');
        final advert = await advertService.fetchAdvertById(eventId);
        if (advert != null) {
          adverts.add(advert);
          debugPrint('İlan eklendi: ${advert.advertName}');
        }
      }
    } catch (e) {
      debugPrint('İlan yükleme hatası: ${e.toString()}');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
