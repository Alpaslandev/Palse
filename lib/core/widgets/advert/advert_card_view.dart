import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/models/advert.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart' as Routes;
import 'package:palseapp/core/services/chat_service.dart';
import 'package:palseapp/core/services/firestore/advert_service.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:palseapp/core/services/firestore/follow_service.dart';
import 'package:palseapp/core/services/firestore/report_service.dart';
import 'package:palseapp/core/widgets/advert/advert_card_view_model.dart';
import 'package:palseapp/core/widgets/advert/widgets/action_buttons.dart';
import 'package:palseapp/core/widgets/advert/widgets/advert_details.dart';
import 'package:palseapp/core/widgets/advert/widgets/advert_image.dart';
import 'package:palseapp/core/widgets/advert/widgets/advert_profile_header.dart';
import 'package:palseapp/core/widgets/advert/widgets/user_list_view.dart';
import 'package:provider/provider.dart';

class AdvertCardView extends StatelessWidget {
  const AdvertCardView({
    super.key,
    required this.advert,
    required this.mode,
  });

  final Advert advert;
  final AdvertCardMode mode;

  @override
  Widget build(BuildContext context) {
    final currentCustomer = context.read<AuthProvider>().user!;
    final authProvider = context.read<AuthProvider>();

    return ChangeNotifierProvider(
      create: (context) => AdvertCardViewModel(
        advert: advert,
        mode: mode,
        currentCustomer: currentCustomer,
        authProvider: authProvider,
        advertService: AdvertService(),
        chatService: ChatService(),
        reportService: ReportService(),
        customerService: CustomerService(),
        followService: FollowService(),
        onShowLikers: () {
          context.pushNamed(
            Routes.userList,
            extra: {
              'users': advert.likers,
              'isLikers': true,
            },
          );
        },
        onShowJoinRequests: () {
          context.pushNamed(
            Routes.userList,
            extra: {
              'users': advert.joinRequestIds,
              'isLikers': false,
              'advertId': advert.advertID,
            },
          );
        },
      ),
      child: Consumer<AdvertCardViewModel>(
        builder: (context, viewModel, child) {
          return Card(
            color: Colors.transparent,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst kısım - Kullanıcı bilgileri ve konum/tarih
                _profileHeader(context),

                // İlan Detayları
                AdvertDetails(advert: advert),

                // Görsel
                AdvertImage(imageUrl: advert.advertImage),

                // Butonlar
                if (mode != AdvertCardMode.friendProfile) ActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileHeader(BuildContext context) {
    final viewModel = context.watch<AdvertCardViewModel>();

    // Success durumu - normal header göster
    return AdvertProfileHeader(
      customer: viewModel.creatorCustomer!,
      currentCustomer: viewModel.currentCustomer,
      advert: advert,
      isFollowing: viewModel.isFollowing,
      isFollowRequestSent: viewModel.isFollowRequestSent,
      isLoading: viewModel.isLoading,
      onFollowTap: () async => await viewModel.toggleFollow(),
    );
  }
}
