import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/core/widgets/animated_list_view.dart';
import 'package:palseapp/features/matching/match_view_model.dart';
import 'package:provider/provider.dart';

// Eşleşme ekranını gösteren ve yöneten view.
class MatchView extends StatelessWidget {
  const MatchView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final bool isPremium = user?.isPremium ?? false;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Giriş yapmalısınız.')),
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
              title: const Text('Eşleşmeler'),
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
                                    'Eşleşme Geçmişi',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
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
                                      backgroundImage: match.photoUrl != null
                                          ? NetworkImage(match.photoUrl!)
                                          : null,
                                      child: match.photoUrl == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    title: Text(match.name ?? ''),
                                    subtitle: Text(
                                      'Eşleşme Tarihi: ${DateFormat.yMMMd('tr_TR').format(match.matchedAt)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Puan: ${match.score}',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                  tooltip: 'Geçmiş',
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
                      child:
                          Center(child: CircularProgressIndicator.adaptive()),
                    )
                  else if (viewModel.matches.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Henüz kimseyle eşleşmedin.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hadi yeni birini bul!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
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
                                backgroundImage: match.photoUrl != null
                                    ? NetworkImage(match.photoUrl!)
                                    : null,
                                child: match.photoUrl == null
                                    ? const Icon(Icons.person, size: 28)
                                    : null,
                              ),
                              title: Text(
                                match.name ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Puan: ${match.score} - ${DateFormat.yMd().format(match.matchedAt)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            bottomNavigationBar: _buildMatchButton(context, viewModel),
          );
        },
      ),
    );
  }

  // Eşleşme butonunu oluşturan widget.
  Widget _buildMatchButton(BuildContext context, MatchViewModel viewModel) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

    if (viewModel.isMatching) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: null,
          style: buttonStyle,
          child: const CircularProgressIndicator.adaptive(
            backgroundColor: Colors.white,
          ),
        ),
      );
    }

    if (!viewModel.canMatch && viewModel.nextMatchDate != null) {
      final formattedDate =
          DateFormat.yMd('tr_TR').add_Hm().format(viewModel.nextMatchDate!);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium banner
          if (!viewModel.isPremium)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Beklemekten Sıkıldın mı?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Premium üye olarak hemen yeni eşleşmeler bulabilirsin!',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      GoRouter.of(context).push('/$paywall');
                    },
                    icon: const Icon(Icons.arrow_forward),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          // Eşleşme butonu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: null,
              style: buttonStyle,
              child: Text('Sonraki Eşleşme: $formattedDate'),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: viewModel.findNewMatches,
        style: buttonStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Yeni Eşleşme Bul'),
            if (viewModel.isPremium) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star, size: 20, color: Colors.amber),
            ],
          ],
        ),
      ),
    );
  }
}
