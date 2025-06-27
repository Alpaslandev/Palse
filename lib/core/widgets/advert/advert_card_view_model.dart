import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/chat_service.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/report_service.dart';

enum AdvertCardMode { home, myAdvert, friendProfile }

class AdvertCardViewModel extends ChangeNotifier {
  final Advert advert;
  final AdvertCardMode mode;
  final Customer currentCustomer;

  // Services (dependency injection)
  final AdvertService _advertService;
  final ChatService _chatService;
  final ReportService _reportService;

  AdvertCardViewModel({
    required this.advert,
    required this.mode,
    required this.currentCustomer,
    required AdvertService advertService,
    required ChatService chatService,
    required ReportService reportService,
  })  : _advertService = advertService,
        _chatService = chatService,
        _reportService = reportService;

  // Mode'a göre davranış
  bool get canLike => mode == AdvertCardMode.home;
  bool get canDelete => mode == AdvertCardMode.myAdvert;
  bool get canJoin => mode == AdvertCardMode.home;

  Future<void> toggleLike() async {/* ... */}
  Future<void> sendJoinRequest() async {/* ... */}
  Future<void> deleteAdvert() async {/* ... */}
}
