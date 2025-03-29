import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/firestore/report_service.dart';
import 'package:palseapp/core/services/notification_service.dart';

class FriendProfileViewModel extends ChangeNotifier {
  final AdvertService advertService = AdvertService();
  final CustomerService customerService = CustomerService();
  final NotificationService notificationService = NotificationService();
  final ReportService reportService = ReportService();
  final AuthProvider authProvider;
  final String customerID;
  Customer? customer;
  List<Advert> adverts = [];
  bool isLoading = false;

  FriendProfileViewModel({required this.customerID, required this.authProvider}) {
    getCustomer();
    addProfileViewers();
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

  // Kullanıcının engellenip engellenmediğini kontrol et
  bool isUserBlocked() {
    final currentUser = authProvider.user;
    if (currentUser == null || currentUser.blockUsers == null) return false;

    return currentUser.blockUsers!.contains(customerID);
  }

  // Kullanıcıyı engelle veya engeli kaldır
  Future<void> toggleBlockUser() async {
    try {
      final currentUser = authProvider.user;
      if (currentUser == null || currentUser.userID == null) return;

      if (isUserBlocked()) {
        // Engeli kaldır
        await reportService.unblockUser(customerID, currentUserId: currentUser.userID!);

        // Kullanıcı modelini güncelle
        if (currentUser.blockUsers != null) {
          final updatedBlockList = List<String>.from(currentUser.blockUsers!);
          updatedBlockList.remove(customerID);

          final updatedUser = currentUser.copyWith(
            blockUsers: updatedBlockList,
          );

          authProvider.updateUser(updatedUser);
        }
      } else {
        // Kullanıcıyı engelle
        await reportService.blockUser(customerID, currentUserId: currentUser.userID!);

        // Kullanıcı modelini güncelle
        final updatedBlockList = currentUser.blockUsers != null ? List<String>.from(currentUser.blockUsers!) : <String>[];

        updatedBlockList.add(customerID);

        final updatedUser = currentUser.copyWith(
          blockUsers: updatedBlockList,
        );

        authProvider.updateUser(updatedUser);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Kullanıcı engelleme/engel kaldırma işleminde hata: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> reportUser(String description) async {
    final report = Report(
      reportedUserId: customerID,
      reporterUserId: authProvider.user?.userID ?? '',
      reportType: ReportType.inappropriateContent.name,
      description: description,
      createdAt: DateTime.now().toIso8601String(),
    );
    try {
      await reportService.createReport(report);
    } catch (e) {
      debugPrint('Kullanıcı raporlanırken hata: ${e.toString()}');
      rethrow;
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
        debugPrint('İlan eklendi: ${advert.title}');
      }
    }
  }

  Future<void> addProfileViewers() async {
    try {
      await customerService.addProfileViewers(customerID, authProvider.user?.userID ?? '');
      debugPrint('Kullanıcı görünümü güncellendi');
    } catch (e) {
      debugPrint('Kullanıcı görünümü güncellenirken hata: $e');
      rethrow;
    }
  }
}
