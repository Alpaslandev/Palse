import 'package:flutter/material.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/services/chat_service.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/firestore/follow_service.dart';
import 'package:palseapp/core/services/firestore/report_service.dart';

enum AdvertCardMode { home, myAdvert, friendProfile }

enum AdvertListField { likers, joinRequests, joinRequestAccepted }

enum CustomerListField { blockedUsers, followedUsers, mutedUsers }

class AdvertCardViewModel extends ChangeNotifier {
  Advert advert;
  final AdvertCardMode mode;
  Customer currentCustomer;

  AuthProvider authProvider;

  // Services
  final AdvertService _advertService;
  final ChatService _chatService;
  final ReportService _reportService;
  final CustomerService _customerService;
  final FollowService _followService;

  // Callbacks for UI actions
  final VoidCallback? onShowLikers;
  final VoidCallback? onShowJoinRequests;

  AdvertCardViewModel({
    required this.advert,
    required this.mode,
    required this.currentCustomer,
    required this.authProvider,
    required AdvertService advertService,
    required ChatService chatService,
    required ReportService reportService,
    required CustomerService customerService,
    required FollowService followService,
    this.onShowLikers,
    this.onShowJoinRequests,
  })  : _advertService = advertService,
        _chatService = chatService,
        _reportService = reportService,
        _customerService = customerService,
        _followService = followService {
    _fetchCreatorCustomer();
  }

  // State
  Customer? _creatorCustomer;
  Customer? get creatorCustomer => _creatorCustomer;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // UI'a özel bool'lar ve veriler

  bool get isMyAdvert => advert.creatorUserID == currentCustomer.userID;
  bool get isLiked => advert.likers.contains(currentCustomer.userID);
  int get likeCount => advert.likers.length;
  bool get isJoinRequestSent =>
      advert.joinRequestIds.contains(currentCustomer.userID);
  bool get isJoinRequestAccepted =>
      advert.joinRequestAcceptedIds.contains(currentCustomer.userID);
  bool get isUserBlocked =>
      currentCustomer.blockUsers?.contains(advert.creatorUserID) ?? false;

  // Follow state'leri
  bool get isFollowing =>
      currentCustomer.followings?.contains(advert.creatorUserID) ?? false;
  bool get isFollowRequestSent =>
      _creatorCustomer?.followingRequests?.contains(currentCustomer.userID) ??
      false;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _fetchCreatorCustomer() async {
    _setLoading(true);
    _creatorCustomer = await _customerService.getCustomer(advert.creatorUserID);
    _setLoading(false);
  }

  // Follow/Unfollow aksiyonu
  Future<void> toggleFollow() async {
    if (currentCustomer.userID == null || _creatorCustomer == null) return;

    final isCurrentlyFollowing = isFollowing;
    final isRequestAlreadySent = isFollowRequestSent;
    final targetUserId = advert.creatorUserID;
    final currentUserId = currentCustomer.userID!;

    await updateCustomerLocally(
      customer: currentCustomer,
      userId: targetUserId,
      field: CustomerListField.followedUsers,
      isAdd: !isCurrentlyFollowing,
      backendCall: () async {
        if (isCurrentlyFollowing) {
          await _followService.unfollowUser(currentUserId, targetUserId);
        } else if (_creatorCustomer!.isPrivate == true &&
            isRequestAlreadySent) {
          await _followService.rejectFollowRequest(targetUserId, currentUserId);
        } else {
          await _followService.followUser(currentUserId, targetUserId);
        }
      },
    );
    notifyListeners();
  }

  // Aksiyonlar
  Future<void> toggleLike() async {
    if (currentCustomer.userID == null) return;

    advert = await updateAdvertLocally(
      advert: advert,
      userId: currentCustomer.userID!,
      field: AdvertListField.likers,
      isAdd: !isLiked,
      backendCall: () async {
        if (isLiked) {
          await _advertService.unlikeAdvert(
            advertId: advert.advertID!,
            userId: currentCustomer.userID!,
          );
        } else {
          await _advertService.likeAdvert(
            advertId: advert.advertID!,
            userId: currentCustomer.userID!,
          );
        }
      },
    );
    notifyListeners();
  }

  Future<void> toggleJoinRequest() async {
    if (currentCustomer.userID == null) return;

    final fieldToUpdate = isJoinRequestAccepted
        ? AdvertListField.joinRequestAccepted
        : AdvertListField.joinRequests;

    advert = await updateAdvertLocally(
      advert: advert,
      userId: currentCustomer.userID!,
      field: fieldToUpdate,
      isAdd: !(isJoinRequestSent || isJoinRequestAccepted),
      backendCall: () async {
        if (isJoinRequestSent || isJoinRequestAccepted) {
          await _advertService.rejectJoinRequest(
            advert.advertID!,
            currentCustomer.userID!,
          );
        } else {
          await _advertService.sendJoinRequest(
            advert.advertID!,
            currentCustomer.userID!,
          );
        }
      },
    );

    notifyListeners();
  }

  // Beğenenleri görüntüleme
  List<String> get likers => advert.likers;

  // Katılım isteklerini görüntüleme
  List<String> get joinRequestUsers => advert.joinRequestIds;

  Future<void> deleteAdvert() async {
    if (advert.advertID == null) return;

    try {
      _setLoading(true);
      await _advertService.deleteAdvert(
          advert.advertID!, currentCustomer.userID!);
      // İlan silindikten sonra parent widget'ın handle etmesi gerekiyor
    } catch (e) {
      debugPrint('İlan silme hatası: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Advert> updateAdvertLocally({
    required Advert advert,
    required String userId,
    required AdvertListField field,
    required bool isAdd,
    required Future<void> Function() backendCall,
  }) async {
    try {
      final currentList = field == AdvertListField.likers
          ? advert.likers
          : field == AdvertListField.joinRequests
              ? advert.joinRequestIds
              : field == AdvertListField.joinRequestAccepted
                  ? advert.joinRequestAcceptedIds
                  : <String>[];

      final updatedList = List<String>.from(currentList);
      isAdd ? updatedList.add(userId) : updatedList.remove(userId);

      final updatedAdvert = field == AdvertListField.likers
          ? advert.copyWith(likers: updatedList)
          : field == AdvertListField.joinRequests
              ? advert.copyWith(joinRequestIds: updatedList)
              : field == AdvertListField.joinRequestAccepted
                  ? advert.copyWith(joinRequestAcceptedIds: updatedList)
                  : advert;

      await backendCall();

      return updatedAdvert;
    } catch (e) {
      debugPrint('Advert güncelleme hatası: $e');

      // rollback: ters işlem uygula
      final currentList = field == AdvertListField.likers
          ? advert.likers
          : field == AdvertListField.joinRequests
              ? advert.joinRequestIds
              : field == AdvertListField.joinRequestAccepted
                  ? advert.joinRequestAcceptedIds
                  : <String>[];

      final rollbackList = List<String>.from(currentList);
      isAdd ? rollbackList.remove(userId) : rollbackList.add(userId);

      final revertedAdvert = field == AdvertListField.likers
          ? advert.copyWith(likers: rollbackList)
          : field == AdvertListField.joinRequests
              ? advert.copyWith(joinRequestIds: rollbackList)
              : field == AdvertListField.joinRequestAccepted
                  ? advert.copyWith(joinRequestAcceptedIds: rollbackList)
                  : advert;

      return revertedAdvert;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCustomerLocally({
    required Customer customer,
    required String userId,
    required CustomerListField field,
    required bool isAdd,
    required Future<void> Function() backendCall,
  }) async {
    try {
      final currentList = field == CustomerListField.blockedUsers
          ? customer.blockUsers ?? <String>[]
          : field == CustomerListField.followedUsers
              ? customer.followings ?? <String>[]
              : <String>[];

      final updatedList = List<String>.from(currentList);
      isAdd ? updatedList.add(userId) : updatedList.remove(userId);

      final updatedCustomer = field == CustomerListField.blockedUsers
          ? customer.copyWith(blockUsers: updatedList)
          : field == CustomerListField.followedUsers
              ? customer.copyWith(followings: updatedList)
              : customer;

      await backendCall();

      // AuthProvider'ı güncelle - tüm uygulama senkronize olsun
      authProvider.updateUser(updatedCustomer);
      currentCustomer = updatedCustomer;
    } catch (e) {
      debugPrint('Customer güncelleme hatası: $e');

      final currentList = field == CustomerListField.blockedUsers
          ? customer.blockUsers ?? <String>[]
          : field == CustomerListField.followedUsers
              ? customer.followings ?? <String>[]
              : <String>[];

      final rollbackList = List<String>.from(currentList);
      isAdd ? rollbackList.remove(userId) : rollbackList.add(userId);

      final revertedCustomer = field == CustomerListField.blockedUsers
          ? customer.copyWith(blockUsers: rollbackList)
          : field == CustomerListField.followedUsers
              ? customer.copyWith(followings: rollbackList)
              : customer;

      // Rollback durumunda da AuthProvider'ı güncelle
      authProvider.updateUser(revertedCustomer);
      currentCustomer = revertedCustomer;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> startOrGetChat() async {
    if (currentCustomer.userID == null) return null;
    return await _chatService.startOrGetChat(
      advert.creatorUserID,
      currentCustomer.userID!,
    );
  }

  Future<void> reportAdvert() async {
    await _reportService.createReport(Report(
      reportedUserId: advert.creatorUserID,
      reporterUserId: currentCustomer.userID ?? '',
      reportType: ReportType.inappropriateAdvert.name,
      description: 'İlan içerik ihlali: "${advert.title}"',
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  Future<void> toggleBlockUser() async {
    if (currentCustomer.userID == null) return;

    final isBlocked = isUserBlocked;
    final targetId = advert.creatorUserID;

    await updateCustomerLocally(
      customer: currentCustomer,
      userId: targetId,
      field: CustomerListField.blockedUsers,
      isAdd: !isBlocked,
      backendCall: () async {
        if (isBlocked) {
          await _reportService.unblockUser(targetId,
              currentUserId: currentCustomer.userID!);
        } else {
          await _reportService.blockUser(targetId,
              currentUserId: currentCustomer.userID!);
        }
      },
    );
    notifyListeners();
  }
}
