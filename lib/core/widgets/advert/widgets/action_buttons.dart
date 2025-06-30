import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/services/firestore/report_service.dart';
import 'package:palseapp/core/widgets/advert/advert_card_view_model.dart';
import 'package:palseapp/core/widgets/animated_like_button.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

// İlan kartı için aksiyon butonlarını içeren widget
class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdvertCardViewModel>();

    // Kullanıcının kendi ilanı için butonlar
    if (viewModel.isMyAdvert) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildButton(context, context.tr('likers'),
                  Icons.visibility_outlined, viewModel.onShowLikers ?? () {}),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildButton(
                  context, context.tr('delete'), Icons.delete_outlined,
                  () async {
                await viewModel.deleteAdvert();
              }, isDelete: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildButton(
                context,
                context.tr('join_request'),
                Icons.person_add_alt_1_outlined,
                viewModel.onShowJoinRequests ?? () {},
                compactMode: true,
              ),
            ),
          ],
        ),
      );
    }

    // Diğer kullanıcıların ilanları için butonlar
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Ana butonlar (Beğen ve Mesaj)
          Row(
            children: [
              if (viewModel.mode == AdvertCardMode.home)
                Expanded(
                  flex: 3,
                  child: _buildLikeButton(context, viewModel),
                ),
              if (viewModel.mode == AdvertCardMode.home)
                const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: _buildButton(
                  context,
                  context.tr('message'),
                  Icons.message_outlined,
                  () => _handleMessageTap(context, viewModel),
                  compactMode: true,
                ),
              ),
              if (viewModel.mode == AdvertCardMode.home)
                const SizedBox(width: 4),
              Expanded(
                flex: 3,
                child: _buildButton(
                  context,
                  viewModel.isJoinRequestAccepted
                      ? context.tr('leave')
                      : viewModel.isJoinRequestSent
                          ? context.tr('waiting')
                          : context.tr('join'),
                  viewModel.isJoinRequestAccepted
                      ? Icons.exit_to_app_outlined
                      : viewModel.isJoinRequestSent
                          ? Icons.schedule_outlined
                          : Icons.person_add_alt_1_outlined,
                  () async => await viewModel.toggleJoinRequest(),
                  compactMode: true,
                ),
              ),
              const SizedBox(width: 4),
              // Şikayet butonu sağ tarafta kompakt
              _buildButton(
                context,
                '',
                Icons.info_outline,
                () => _showReportBottomSheet(context, viewModel),
                isReport: true,
                compactMode: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Animasyonlu like butonu oluşturur
  Widget _buildLikeButton(BuildContext context, AdvertCardViewModel viewModel) {
    return GestureDetector(
      onTap: () async {
        // Sadece like yapılıyorsa vibration ekle (unlike'ta değil)
        if (!viewModel.isLiked) {
          _triggerHapticFeedback();
        }
        await viewModel.toggleLike();
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: const BorderRadius.all(Radius.circular(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedLikeButton(
              isLiked: viewModel.isLiked,
              likeCount: viewModel.likeCount,
              onTap: () {}, // Boş bırak, üst GestureDetector handle edecek
              size: 18,
              fontSize: 11,
            ),
            const SizedBox(width: 4),
            Text(
              '| ${context.tr('like')}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hafif titreşim efekti
  Future<void> _triggerHapticFeedback() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        // Çok hafif titreşim (3ms) - like için minimal
        Vibration.vibrate(duration: 5);
      }
    } catch (e) {
      // Titreşim desteklenmiyorsa sessizce devam et
      debugPrint('Titreşim desteklenmiyor: $e');
    }
  }

  // Mesaj gönderme işlemini handle eden metod
  void _handleMessageTap(
      BuildContext context, AdvertCardViewModel viewModel) async {
    final chatId = await viewModel.startOrGetChat();
    if (chatId != null && context.mounted) {
      context.push(
          '/chats/$chatId?otherId=${viewModel.advert.creatorUserID}&currentId=${viewModel.currentCustomer.userID}');
    }
  }

  // Şikayet/Bildir bottom sheet'ini gösteren metod
  void _showReportBottomSheet(
      BuildContext context, AdvertCardViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.red),
              title: Text(context.tr('report_listing')),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await viewModel.reportAdvert();
                  if (context.mounted) {
                    ScaffoldMess.showSuccessSnackBar(context.tr('report_sent'));
                  }
                } catch (e) {
                  debugPrint('İlan şikayet edilirken hata: ${e.toString()}');
                  if (context.mounted) {
                    ScaffoldMess.showErrorSnackBar(
                        context.tr('error_occurred'));
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(
                  viewModel.isUserBlocked ? Icons.person_add : Icons.block,
                  color:
                      viewModel.isUserBlocked ? Colors.green : Colors.orange),
              title: Text(viewModel.isUserBlocked
                  ? context.tr('unblock_user')
                  : context.tr('block_user')),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await viewModel.toggleBlockUser();
                  if (context.mounted) {
                    ScaffoldMess.showSuccessSnackBar(viewModel.isUserBlocked
                        ? context.tr('user_unblocked')
                        : context.tr('user_blocked'));
                  }
                } catch (e) {
                  debugPrint(
                      'Kullanıcı engelleme/engel kaldırma işleminde hata: ${e.toString()}');
                  if (context.mounted) {
                    ScaffoldMess.showErrorSnackBar(
                        context.tr('error_occurred'));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Özel buton tasarımı oluşturur
  Widget _buildButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool showCount = false,
    bool isDelete = false,
    bool isReport = false,
    bool compactMode = false,
  }) {
    final viewModel = context.watch<AdvertCardViewModel>();
    // Buton rengi belirleme
    Color iconColor = Colors.black;
    if ((showCount && viewModel.isLiked) || isDelete) {
      iconColor = Colors.red;
    } else if (isReport) {
      iconColor = Colors.grey;
    }

    // Şikayet butonu için özel tasarım
    if (isReport) {
      return Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: const BorderRadius.all(Radius.circular(50)),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: iconColor, size: 20),
          onPressed: onPressed,
        ),
      );
    }

    // Yazı boyutunu kompakt mod için küçült
    final double fontSize = compactMode ? 11.0 : 12.0;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: const BorderRadius.all(Radius.circular(50)),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: compactMode
              ? const EdgeInsets.symmetric(horizontal: 6)
              : const EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: compactMode ? 18 : 20),
            if (showCount)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  viewModel.likeCount.toString(),
                  style: TextStyle(color: Colors.black, fontSize: fontSize),
                ),
              ),
          ],
        ),
        label: RichText(
          text: TextSpan(
            style: TextStyle(color: Colors.black, fontSize: fontSize),
            children: [
              const TextSpan(
                text: '| ',
                style: TextStyle(color: Colors.grey),
              ),
              TextSpan(text: label),
            ],
          ),
        ),
      ),
    );
  }
}
