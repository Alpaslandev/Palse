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
import 'package:palseapp/features/matching/widgets/match_list_item_widget.dart';
import 'package:palseapp/features/matching/widgets/empty_matches_widget.dart';
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
                    EmptyMatchesWidget(viewModel: viewModel)
                  else ...[
                    Expanded(
                      child: AnimatedListView(
                        items: viewModel.matches,
                        animationDuration: const Duration(milliseconds: 300),
                        staggerDelay: const Duration(milliseconds: 120),
                        curve: Curves.easeOutBack,
                        shrinkWrap: true,
                        itemBuilder: (context, match, index) {
                          return MatchListItemWidget(match: match);
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
