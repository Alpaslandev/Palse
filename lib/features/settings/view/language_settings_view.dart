import 'package:flutter/material.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/locale_provider.dart';
import 'package:provider/provider.dart';

class LanguageSettingsView extends StatelessWidget {
  const LanguageSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

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
            onTap: () {
              localeProvider.setTurkish();
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
            onTap: () {
              localeProvider.setEnglish();
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
