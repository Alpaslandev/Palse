import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/services/firestore/follow_service.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/core/widgets/scaffold_mess.dart';
import 'package:palseapp/features/achievement/achievement_service.dart';

// İlan kart profil başlık widget'ı
class AdvertProfileHeader extends StatefulWidget {
  const AdvertProfileHeader({
    super.key,
    required this.customer,
    required this.currentCustomer,
    required this.advert,
  });

  final Customer customer;
  final Customer currentCustomer;
  final Advert advert;

  @override
  State<AdvertProfileHeader> createState() => _AdvertProfileHeaderState();
}

class _AdvertProfileHeaderState extends State<AdvertProfileHeader> {
  final FollowService _followService = FollowService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.pushNamed(friendProfile, extra: widget.advert.creatorUserID);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kullanıcı bilgileri
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sol taraf - Profil resmi
                CircleProfilePicture(
                  imageUrl: widget.customer.profilePictureUrl,
                  radius: 30,
                ),

                const SizedBox(width: 10),

                // Sağ taraf - Kullanıcı bilgileri (3 satır)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Satır: İsim, rozetler ve takip butonu
                      Row(
                        children: [
                          Text(
                            widget.customer.firstName ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (widget.customer.verification ?? false)
                            const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Icon(Icons.verified,
                                  color: Colors.blue, size: 14),
                            ),
                          if (widget.customer.isPremium ?? false)
                            const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Icon(Icons.verified,
                                  color: Colors.yellow, size: 14),
                            ),
                          const Spacer(),

                          // Takip butonu - kendi profilinde gösterme
                          if (widget.customer.userID !=
                              widget.currentCustomer.userID)
                            _buildFollowButton(),

                          const SizedBox(width: 8),

                          // Rating
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/vectors/vector_7_x2.svg',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                widget.customer.getAverage().toInt().toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // 2. Satır: Kullanıcı rütbesi
                      if (widget.customer.totalXp > 0)
                        Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Builder(builder: (context) {
                                  final rank = AchievementService()
                                      .getUserRankFromXp(
                                          widget.customer.totalXp);
                                  return Text(
                                    "${rank.icon} ${AchievementService().getLocalizedRankTitle(rank, context)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),

                      // 3. Satır: Etkinlik türü ve tarih
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.advert.advertType.getText(context),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy')
                                .format(widget.advert.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Konum ve Etkinlik Tarihi bilgisi
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Konum bilgisi
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          const WidgetSpan(
                            child: Icon(Icons.location_on_outlined,
                                size: 12, color: Colors.blue),
                          ),
                          TextSpan(
                            text:
                                ' ${widget.advert.location.displayStringWithDistance(widget.currentCustomer.location!)}',
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Etkinlik tarihi
                  RichText(
                    text: TextSpan(
                      children: [
                        const WidgetSpan(
                          child: Icon(Icons.calendar_month_outlined,
                              size: 12, color: Colors.blue),
                        ),
                        TextSpan(
                          text:
                              ' ${DateFormat('dd/MM/yyyy').format(widget.advert.startEventDate)} - ${DateFormat('HH:mm').format(widget.advert.startEventDate)}',
                          style:
                              const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Takip butonunu oluşturan metod
  Widget _buildFollowButton() {
    final isFollowing = FollowService.isFollowing(
        widget.currentCustomer, widget.customer.userID!);
    final isRequestSent = FollowService.isFollowRequestSent(
        widget.customer, widget.currentCustomer.userID!);

    String buttonText;
    IconData buttonIcon;
    Color buttonColor = Colors.blue;

    if (isFollowing) {
      buttonText = context.tr('unfollow');
      buttonIcon = Icons.person_remove_outlined;
      buttonColor = Colors.red;
    } else if (widget.customer.isPrivate == true && isRequestSent) {
      buttonText = context.tr('request_sent');
      buttonIcon = Icons.schedule_outlined;
      buttonColor = Colors.orange;
    } else if (widget.customer.isPrivate == true) {
      buttonText = context.tr('send_request');
      buttonIcon = Icons.person_add_outlined;
    } else {
      buttonText = context.tr('follow');
      buttonIcon = Icons.person_add_outlined;
    }

    return _isLoading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
            ),
          )
        : Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: buttonColor.withValues(alpha: 0.1),
              border: Border.all(color: buttonColor),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextButton.icon(
              onPressed: () => _handleFollowTap(isFollowing, isRequestSent),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(buttonIcon, color: buttonColor, size: 12),
              label: Text(
                buttonText,
                style: TextStyle(color: buttonColor, fontSize: 10),
              ),
            ),
          );
  }

  // Takip butonuna tıklandığında çalışan metod
  Future<void> _handleFollowTap(bool isFollowing, bool isRequestSent) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = widget.currentCustomer.userID!;
      final targetUserId = widget.customer.userID!;

      if (isFollowing) {
        // Takipten çık
        await _followService.unfollowUser(currentUserId, targetUserId);
        if (mounted) {
          ScaffoldMess.showSuccessSnackBar(context.tr('unfollowed_user'));
        }
      } else if (widget.customer.isPrivate == true && isRequestSent) {
        // İsteği iptal et - followingRequests'ten çıkar
        await _followService.rejectFollowRequest(targetUserId, currentUserId);
        if (mounted) {
          ScaffoldMess.showSuccessSnackBar(context.tr('request_cancelled'));
        }
      } else {
        // Takip et veya istek gönder
        await _followService.followUser(currentUserId, targetUserId);
        if (widget.customer.isPrivate == true) {
          if (mounted) {
            ScaffoldMess.showSuccessSnackBar(context.tr('follow_request_sent'));
          }
        } else {
          if (mounted) {
            ScaffoldMess.showSuccessSnackBar(context.tr('user_followed'));
          }
        }
      }

      // Auth provider stream otomatik olarak güncellenecek
    } catch (e) {
      debugPrint('Takip işlemi hatası: $e');
      if (mounted) {
        ScaffoldMess.showErrorSnackBar(context.tr('error_occurred'));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
