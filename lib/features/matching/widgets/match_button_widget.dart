import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:palseapp/features/matching/match_view_model.dart';

// Eşleşme butonunu oluşturan widget.
class MatchButtonWidget extends StatelessWidget {
  final MatchViewModel viewModel;

  const MatchButtonWidget({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
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
      final formattedDate = DateFormat.yMd('tr_TR').add_Hm().format(viewModel.nextMatchDate!);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Premium banner
          if (!viewModel.isPremium)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade400.withValues(alpha: 0.15),
                    Colors.amber.shade300.withValues(alpha: 0.1),
                    Colors.amber.shade200.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.shade300.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Üst kısım - İkon ve metin
                  Row(
                    children: [
                      // Premium ikonu
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.amber.shade300,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.diamond,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Metin içeriği
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title tek satırda
                            Text(
                              context.tr('match_premium_tired'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.amber.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('match_premium_info'),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Premium özellikler tek satırda
                            Row(
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: Colors.amber.shade600,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  context.tr('match_premium_unlimited'),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.timer,
                                  color: Colors.amber.shade600,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  context.tr('match_premium_no_wait'),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Alt kısım - Premium butonu
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade500,
                            Colors.amber.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            GoRouter.of(context).push('/$paywall');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Premium\'a Geç',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
              child: Text(context.tr('match_next_match').replaceAll('{date}', formattedDate)),
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
            Text(context.tr('match_find_new')),
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
