// Premium buton
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/routes/routes.dart';

class PremiumButton extends StatelessWidget {
  const PremiumButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          context.pushNamed(paywall);
        },
        icon: const Icon(Icons.diamond, color: Colors.amber, size: 30),
        label: Text(
          context.tr('get_premium'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
