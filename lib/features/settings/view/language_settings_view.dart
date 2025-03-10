import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/provider/locale_provider.dart';
import 'package:palseapp/core/services/firestore/customer_service.dart';
import 'package:provider/provider.dart';

class LanguageSettingsView extends StatelessWidget {
  const LanguageSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;
    final customerService = CustomerService();
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('language_settings')),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Türkçe'),
            subtitle: const Text('Turkish'),
            leading: const CircleAvatar(
              child: Text('TR'),
            ),
            trailing: currentLocale == 'tr' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () async {
              localeProvider.setTurkish();
              await customerService.updateCustomer(authProvider.user!.userID!, authProvider.user!.copyWith(languagePreference: 'tr'));
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('English'),
            subtitle: const Text('İngilizce'),
            leading: const CircleAvatar(
              child: Text('EN'),
            ),
            trailing: currentLocale == 'en' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () async {
              localeProvider.setEnglish();
              await customerService.updateCustomer(authProvider.user!.userID!, authProvider.user!.copyWith(languagePreference: 'en'));
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              context.tr('language_change_info'),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
