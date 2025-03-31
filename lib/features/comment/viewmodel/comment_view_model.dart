import 'package:flutter/material.dart';
import 'package:palseapp/core/models/comment_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/firestore/report_service.dart';
import 'package:palseapp/features/achievement/achievement_service.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';
import 'package:palseapp/core/localization/locale_manager.dart';
import 'package:palseapp/core/constant/notifications_enum.dart';
import 'package:palseapp/core/services/shared_pref_service.dart';

class CommentViewModel extends ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  final AchievementService _achievementService = AchievementService();
  final ReportService _reportService = ReportService();
  final Customer _friendCustomer;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  CommentViewModel(friendCustomer) : _friendCustomer = friendCustomer {
    _comments = _friendCustomer.comments ?? [];
  }

  List<Comment> _comments = [];
  List<Comment> get comments => _comments;

  Future<void> addComment(Comment comment, String currentUserId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _customerService.addComment(_friendCustomer.userID!, comment);
      _comments.add(comment);

      debugPrint('Yorum eklendi: ${comment.toString()}');

      if (_friendCustomer.userID != null && currentUserId.isNotEmpty) {
        final rewards = await _achievementService.handleCommentAction(
          currentUserId,
          _friendCustomer.userID!,
        );

        if (rewards['commenterXp']! > 0) {
          ScaffoldMess.showSuccessSnackBar(LocaleManager.translateWithParams('comment_reward_earned', {'xp': rewards['commenterXp'].toString()}));
        }

        if (rewards['receiverXp']! > 0) {
          await _saveCommentReceivedNotification(_friendCustomer.userID!, rewards['receiverXp']!, comment.commenterName ?? 'Bir kullanıcı');
        }

        debugPrint('Yorum ödülleri: Yazan: ${rewards['commenterXp']} XP, Alan: ${rewards['receiverXp']} XP');
      } else {
        debugPrint('Ödül verilemedi: Kullanıcı ID eksik');
      }
    } catch (e) {
      debugPrint('Yorum ekleme hatası: $e');
      ScaffoldMess.showErrorSnackBar(LocaleManager.translate('comment_error'));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCommentReceivedNotification(String receiverId, int xpAmount, String commenterName) async {
    try {
      await SharedPrefService.saveNotificationWithEnum(
        type: NotificationsEnum.commentReceived.name,
        title: LocaleManager.translate('comment_received_title'),
        body: LocaleManager.translateWithParams('comment_received_body', {'commenter': commenterName, 'xp': xpAmount.toString()}),
      );
      debugPrint('Yorum alan kişi için bildirim kaydedildi: $receiverId');
    } catch (e) {
      debugPrint('Bildirim kaydedilirken hata: $e');
    }
  }

  Future<void> deleteComment(Comment comment) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _customerService.deleteComment(_friendCustomer.userID!, comment);
      _comments.remove(comment);
    } catch (e) {
      debugPrint('Yorum silme hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reportComment(Comment comment, String currentUserId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _reportService.createReport(Report(
        reportedUserId: comment.commenterID!,
        reporterUserId: currentUserId,
        reportType: ReportType.inappropriateComment.name,
        description: 'Yorum içerik ihlali: "${comment.comment}"',
        createdAt: DateTime.now().toIso8601String(),
      ));

      ScaffoldMess.showSuccessSnackBar(LocaleManager.translate('comment_reported_success'));
      debugPrint('Yorum başarıyla şikayet edildi: ${comment.comment}');
    } catch (e) {
      ScaffoldMess.showErrorSnackBar(LocaleManager.translate('comment_report_error'));
      debugPrint('Yorum şikayet etme hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
