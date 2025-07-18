import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/matching/match_view_model.dart';
import 'package:provider/provider.dart';

// Eşleşme ekranını gösteren ve yöneten view.
class MatchView extends StatelessWidget {
  const MatchView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Giriş yapmalısınız.')),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => MatchViewModel(uid: user.userID!),
      child: Consumer<MatchViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Eşleşmeler'),
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
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Henüz kimseyle eşleşmedin.\nHadi yeni birini bul!',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
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
                            title: Text(match.name),
                            subtitle: Text(
                                'Puan: ${match.score} - ${DateFormat.yMd().format(match.matchedAt)}'),
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
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: null,
          style: buttonStyle,
          child: Text('Sonraki Eşleşme: $formattedDate'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: viewModel.findNewMatches,
        style: buttonStyle,
        child: const Text('Yeni Eşleşme Bul'),
      ),
    );
  }
}
