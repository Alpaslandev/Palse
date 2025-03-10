import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/models/customer.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/widgets/circle_profile_picture.dart';
import 'package:palseapp/features/achievement/user_achievements.dart';
import 'package:palseapp/core/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Kullanıcı ilanlarını gösteren kart tasarımı
class AdvertCard extends StatelessWidget {
  const AdvertCard({
    super.key,
    required this.advert,
    this.isUserAdvert = false,
    this.onProfileTap,
    this.onLikeTap,
    this.onMessageTap,
    this.isLiked = false,
    this.onDeleteTap,
    this.onSeeViewersTap,
    this.isMyLikes = false,
    this.isFriendProfile = false,
  });

  final Advert advert;
  final bool isUserAdvert;
  final bool isMyLikes;
  final bool isFriendProfile;

  final VoidCallback? onProfileTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onSeeViewersTap;
  final bool isLiked;

  @override
  Widget build(BuildContext context) {
    final currentCustomer = context.read<AuthProvider>().user!;
    final chatsService = ChatService();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst kısım - Kullanıcı bilgileri ve konum/tarih
          _profileHeader(context, currentCustomer),

          // İlan Detayları
          _buildAdvertDetails(),

          // Görsel
          _buildAdvertImage(),

          // Butonlar
          if (!isFriendProfile) _buildActionButtons(context, currentCustomer, chatsService),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context, Customer currentCustomer) {
    Customer? customer;
    // Eğer creator bilgileri tam değilse FutureBuilder kullan
    return FutureBuilder(
        future: FirebaseFirestore.instance.collection('customers').doc(advert.creatorUserID).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: CircularProgressIndicator()),
              title: Text('...'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Icon(Icons.error)),
              title: Text('Kullanıcı bulunamadı'),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          customer = Customer.fromJson(userData, snapshot.data!.id);

          return _buildProfileHeader(
            context: context,
            customer: customer!,
            currentCustomer: currentCustomer,
          );
        });
  }

  // Profil header'ını oluşturan yardımcı metod
  Widget _buildProfileHeader({
    required Customer customer,
    required BuildContext context,
    required Customer currentCustomer,
  }) {
    UserAchievements userAchievements = UserAchievements(xp: customer.xp);
    return InkWell(
      onTap: () {
        context.push(friendProfile, extra: advert.creatorUserID);
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
                  imageUrl: customer.profilePictureUrl,
                  radius: 30, // Profil fotoğrafı için uygun radius
                ),

                const SizedBox(width: 10),

                // Sağ taraf - Kullanıcı bilgileri (3 satır)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Satır: İsim ve rozetler
                      Row(
                        children: [
                          Text(
                            customer.firstName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (customer.verification ?? false)
                            const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Icon(Icons.verified, color: Colors.blue, size: 14),
                            ),
                          if (customer.isPremium ?? false)
                            const Padding(
                              padding: EdgeInsets.only(left: 2),
                              child: Icon(Icons.verified, color: Colors.yellow, size: 14),
                            ),
                          const Spacer(),
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
                      Text(
                        "${userAchievements.rank.icon} ${context.tr(userAchievements.rank.titleKey)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                          color: Colors.grey,
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
                            DateFormat('dd/MM/yyyy').format(advert.createdAt!),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                            child: Icon(Icons.location_on_outlined, size: 12, color: Colors.blue),
                          ),
                          TextSpan(
                            text: ' ${advert.location?.displayStringWithDistance(currentCustomer.location!)}',
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
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
                          child: Icon(Icons.calendar_month_outlined, size: 12, color: Colors.blue),
                        ),
                        TextSpan(
                          text: ' ${DateFormat('dd/MM/yyyy').format(advert.startEventDate!)} - ${DateFormat('HH:mm').format(advert.startEventDate!)}',
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
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

  // İlan başlığı ve açıklamasını gösteren widget
  Widget _buildAdvertDetails() {
    // Açıklamanın tamamını gösterip göstermeyeceğimizi kontrol eden state
    final ValueNotifier<bool> showFullDescription = ValueNotifier<bool>(false);

    return StatefulBuilder(builder: (context, setState) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlan başlığı
            Text(
              advert.advertName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // İlan açıklaması
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advert.description,
                  style: const TextStyle(fontSize: 12),
                  maxLines: showFullDescription.value ? null : 5,
                  overflow: showFullDescription.value ? TextOverflow.visible : TextOverflow.ellipsis,
                ),

                // Açıklama 5 satırdan uzunsa "Devamını Gör" butonu göster
                if (_isDescriptionLong(advert.description))
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showFullDescription.value = !showFullDescription.value;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        showFullDescription.value ? context.tr('show_less') : context.tr('show_more'),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // Açıklamanın uzun olup olmadığını kontrol eden yardımcı metod
  bool _isDescriptionLong(String description) {
    // Yaklaşık olarak 5 satırdan uzun olup olmadığını kontrol et
    // Ortalama bir satırda 50 karakter olduğunu varsayalım
    return description.length > 200;
  }

  // İlan görselini gösteren widget
  Widget _buildAdvertImage() {
    if (!advert.advertImage.contains('assets/images/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: advert.advertImage,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        advert.advertImage,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
      ),
    );
  }

  // Aksiyon butonlarını gösteren widget
  Widget _buildActionButtons(BuildContext context, Customer currentCustomer, ChatService chatsService) {
    // Kullanıcının kendi ilanı için butonlar
    if (isUserAdvert) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildButton(context.tr('likers'), Icons.visibility_outlined, onSeeViewersTap ?? () {}),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildButton(context.tr('delete'), Icons.delete_outlined, onDeleteTap ?? () {}, isDelete: true),
            ),
          ],
        ),
      );
    }

    // Diğer kullanıcıların ilanları için butonlar
    if (!isUserAdvert) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            // Ana butonlar (Beğen ve Mesaj)
            Row(
              children: [
                if (!isMyLikes)
                  Expanded(
                    flex: 3,
                    child: _buildButton(
                      context.tr('like'),
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      onLikeTap ?? () {},
                      showCount: true,
                    ),
                  ),
                if (!isMyLikes) const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildButton(
                    context.tr('message'),
                    Icons.message_outlined,
                    () => _handleMessageTap(context, currentCustomer, chatsService),
                  ),
                ),
                const SizedBox(width: 8),
                // Şikayet butonu sağ tarafta kompakt
                _buildButton(
                  '',
                  Icons.info_outline,
                  () => _showReportBottomSheet(context),
                  isReport: true,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // Mesaj gönderme işlemini handle eden metod
  void _handleMessageTap(BuildContext context, Customer currentCustomer, ChatService chatsService) async {
    final userId = currentCustomer.userID;
    if (userId == null) return;

    final chatId = await chatsService.startOrGetChat(
      advert.creatorUserID,
      userId,
    );

    if (context.mounted) {
      context.push('/chats/$chatId?otherId=${advert.creatorUserID}&currentId=$userId');
    }
  }

  // Şikayet/Bildir bottom sheet'ini gösteren metod
  void _showReportBottomSheet(BuildContext context) {
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
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('report_sent'))),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.orange),
              title: Text(context.tr('block_user')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('user_blocked'))),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

// Özel buton tasarımı oluşturur
  Widget _buildButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool showCount = false,
    bool isDelete = false,
    bool isReport = false,
  }) {
    // Buton rengi belirleme
    Color iconColor = Colors.black;
    if (showCount || isDelete) {
      iconColor = Colors.red;
    } else if (isReport) {
      iconColor = Colors.grey;
    }

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: const BorderRadius.all(Radius.circular(50)),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Row(
          children: [
            Icon(icon, color: iconColor),
            if (showCount) // Sadece showCount true ise sayıyı göster
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  advert.likers.length.toString(),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
          ],
        ),
        label: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black),
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
