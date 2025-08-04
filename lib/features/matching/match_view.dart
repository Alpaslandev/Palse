import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/routes/routes.dart' as Routes;
import 'package:palseapp/core/widgets/animated_list_view.dart';
import 'package:palseapp/features/matching/match_view_model.dart';
import 'package:palseapp/features/matching/widgets/matching_animation_widget.dart';
import 'package:palseapp/features/matching/widgets/feature_item_widget.dart';
import 'package:palseapp/features/matching/widgets/match_button_widget.dart';
import 'package:provider/provider.dart';

// Eşleşme ekranını gösteren ve yöneten view.
class MatchView extends StatelessWidget {
  const MatchView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final bool isPremium = user?.isPremium ?? false;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text(context.tr('match_login_required'))),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => MatchViewModel(
        uid: user.userID!,
        isPremium: isPremium,
      ),
      child: Consumer<MatchViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(context.tr('match_title')),
              actions: [
                // Geçmiş butonu
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Modal handle
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Başlık
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.history, size: 24),
                                  const SizedBox(width: 12),
                                  Text(
                                    context.tr('match_history'),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // Geçmiş listesi
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: viewModel.matches.length,
                                itemBuilder: (context, index) {
                                  final match = viewModel.matches[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: match.photoUrl != null ? NetworkImage(match.photoUrl!) : null,
                                      child: match.photoUrl == null ? const Icon(Icons.person) : null,
                                    ),
                                    title: Text(match.name ?? ''),
                                    subtitle: Text(
                                      context.tr('match_date').replaceAll('{date}', DateFormat.yMMMd('tr_TR').format(match.matchedAt)),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: SizedBox(
                                      width: 100,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '%${((match.score / 140.0) * 100).clamp(0, 100).round()}',
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: (match.score / 140.0).clamp(0.0, 1.0),
                                              backgroundColor: Colors.grey.shade200,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).primaryColor.withOpacity(0.7),
                                              ),
                                              minHeight: 3.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  tooltip: context.tr('match_history_tooltip'),
                ),
                const SizedBox(width: 8), // Sağ kenar boşluğu
              ],
            ),
            body: RefreshIndicator(
              onRefresh: viewModel.refresh,
              child: Column(
                children: [
                  if (viewModel.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator.adaptive()),
                    )
                  else if (viewModel.isMatching)
                    const Expanded(
                      child: MatchingAnimationWidget(),
                    )
                  else if (viewModel.matches.isEmpty)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Ana ikon container'ı
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(context).primaryColor.withOpacity(0.1),
                                        Theme.of(context).primaryColor.withOpacity(0.05),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.favorite_border,
                                    size: 50,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Başlık
                                Text(
                                  context.tr('match_no_matches'),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                // Açıklama metni
                                Text(
                                  context.tr('match_find_someone'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                // Özellikler listesi
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      FeatureItemWidget(
                                        icon: Icons.psychology,
                                        title: context.tr('match_feature_smart'),
                                        description: context.tr('match_feature_smart_desc'),
                                      ),
                                      const SizedBox(height: 16),
                                      FeatureItemWidget(
                                        icon: Icons.location_on,
                                        title: context.tr('match_feature_local'),
                                        description: context.tr('match_feature_local_desc'),
                                      ),
                                      const SizedBox(height: 16),
                                      FeatureItemWidget(
                                        icon: Icons.verified,
                                        title: context.tr('match_feature_safe'),
                                        description: context.tr('match_feature_safe_desc'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Premium bilgi kartı
                                if (!viewModel.isPremium)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.amber.withOpacity(0.1),
                                          Colors.amber.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                context.tr('match_premium_benefit'),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                context.tr('match_premium_benefit_desc'),
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Expanded(
                      child: AnimatedListView(
                        items: viewModel.matches,
                        animationDuration: const Duration(milliseconds: 300),
                        staggerDelay: const Duration(milliseconds: 120),
                        curve: Curves.easeOutBack,
                        shrinkWrap: true,
                        itemBuilder: (context, match, index) {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundImage: match.photoUrl != null ? NetworkImage(match.photoUrl!) : null,
                                child: match.photoUrl == null ? const Icon(Icons.person, size: 28) : null,
                              ),
                              title: Text(
                                match.name ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(2),
                                          child: LinearProgressIndicator(
                                            value: (match.score / 140.0).clamp(0.0, 1.0),
                                            backgroundColor: Colors.grey.shade200,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Theme.of(context).primaryColor.withOpacity(0.7),
                                            ),
                                            minHeight: 3.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '%${((match.score / 140.0) * 100).clamp(0, 100).round()}',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat.yMd().format(match.matchedAt),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onTap: () {
                                context.pushNamed(Routes.friendProfile, extra: match.uid);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            bottomNavigationBar: MatchButtonWidget(viewModel: viewModel),
          );
        },
      ),
    );
  }
}
