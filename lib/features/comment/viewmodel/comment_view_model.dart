import 'package:flutter/material.dart';
import 'package:palseapp/core/models/comment_model.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/notification_service.dart';

class CommentViewModel extends ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  final NotificationService _notificationService = NotificationService();
  final Customer _friendCustomer;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  CommentViewModel(friendCustomer) : _friendCustomer = friendCustomer {
    _comments = _friendCustomer.comments ?? [];
  }

  List<Comment> _comments = [];
  List<Comment> get comments => _comments;

  Future<void> addComment(Comment comment) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _customerService.addComment(_friendCustomer.userID!, comment);
      _comments.add(comment);
      await _notificationService.sendNotification(
        receiverId: _friendCustomer.userID!,
        notificationType: 'comment',
      );
      debugPrint('Yorum eklendi: ${comment.toString()}');
    } catch (e) {
      debugPrint('Yorum ekleme hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<void> reportComment(Comment comment) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _customerService.reportComment(_friendCustomer.userID!, comment);
    } catch (e) {
      debugPrint('Yorum şikayet etme hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
