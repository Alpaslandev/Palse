import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
// ignore: library_prefixes
import 'package:palseapp/core/routes/routes.dart' as Routes;
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/features/achievement/achievement_service.dart';

// İlan kart profil başlık widget'ı
class AdvertProfileHeader extends StatelessWidget {
  const AdvertProfileHeader({
    super.key,
    required this.customer,
    required this.currentCustomer,
    required this.advert,
    required this.isFollowing,
    required this.isFollowRequestSent,
    required this.isLoading,
    required this.onFollowTap,
  });

  final Customer customer;
  final Customer currentCustomer;
  final Advert advert;
  final bool isFollowing;
  final bool isFollowRequestSent;
  final bool isLoading;
  final VoidCallback onFollowTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.pushNamed(Routes.friendProfile, extra: customer.userID),
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
                  imageUrl: customer.profilePictureUrl,
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
                            customer.firstName ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (customer.verification ?? false)
                            const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Icon(Icons.verified,
                                  color: Colors.blue, size: 14),
                            ),
                          if (customer.isPremium ?? false)
                            const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Icon(Icons.verified,
                                  color: Colors.yellow, size: 14),
                            ),
                          const Spacer(),

                          // Takip butonu - kendi profilinde gösterme
                          if (customer.userID != currentCustomer.userID)
                            _buildFollowButton(context),

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
                                customer.getAverage().toInt().toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // 2. Satır: Kullanıcı rütbesi
                      if (customer.totalXp > 0)
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
                                      .getUserRankFromXp(customer.totalXp);
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
                            advert.advertType.getText(context),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(advert.createdAt),
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
                                ' ${advert.location.displayStringWithDistance(currentCustomer.location!)}',
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
                              ' ${DateFormat('dd/MM/yyyy').format(advert.startEventDate)} - ${DateFormat('HH:mm').format(advert.startEventDate)}',
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
  Widget _buildFollowButton(BuildContext context) {
    String buttonText;
    IconData buttonIcon;
    Color buttonColor = Colors.blue;

    if (isFollowing) {
      buttonText = context.tr('unfollow');
      buttonIcon = Icons.person_remove_outlined;
      buttonColor = Colors.red;
    } else if (customer.isPrivate == true && isFollowRequestSent) {
      buttonText = context.tr('request_sent');
      buttonIcon = Icons.schedule_outlined;
      buttonColor = Colors.orange;
    } else if (customer.isPrivate == true) {
      buttonText = context.tr('send_request');
      buttonIcon = Icons.person_add_outlined;
    } else {
      buttonText = context.tr('follow');
      buttonIcon = Icons.person_add_outlined;
    }

    return isLoading
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
              onPressed: onFollowTap,
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
}
