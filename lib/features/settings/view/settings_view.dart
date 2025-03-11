import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:palseapp/core/constant/app_constant.dart';
import 'package:palseapp/core/localization/app_localizations.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/core/provider/locale_provider.dart';
import 'package:palseapp/core/provider/theme_provider.dart';
import 'package:palseapp/core/routes/routes.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: ListView(
        children: [
          _SectionTitle(title: context.tr('user')),
          _SettingsTile(
            icon: Icons.person_outline,
            title: context.tr('profile'),
            trailing: authProvider.user?.verification == false
                ? Text(
                    context.tr('account_not_verified'),
                    style: const TextStyle(color: Colors.red),
                  )
                : Text(
                    context.tr('account_verified'),
                    style: const TextStyle(color: Colors.green),
                  ),
            onTap: () => context.pushNamed(editProfile, extra: authProvider.user),
          ),
          _SectionTitle(title: context.tr('application')),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: context.tr('notification'),
            onTap: () => context.pushNamed(editNotification),
          ),
          _SettingsTile(
            icon: Icons.emoji_events_outlined,
            title: 'XP Test Sayfası',
            subtitle: 'XP ve görev sistemini test etmek için',
            onTap: () => context.pushNamed('achievementTest'),
          ),
          // Firestore yedekleme seçeneği
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Firestore Yedekleme',
            subtitle: 'Koleksiyonları yedeklemek için',
            onTap: () => context.pushNamed(firestoreBackup),
          ),
          // Tema seçim seçeneği
          SwitchListTile(
            title: Text(context.tr('dark_theme')),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.blue,
            ),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          // Dil ayarları seçeneği
          _SettingsTile(
            icon: Icons.language,
            title: context.tr('app_language'),
            trailing: Text(
              localeProvider.locale.languageCode == 'tr' ? 'Türkçe' : 'English',
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () => context.pushNamed(languageSettings),
          ),
          _SectionTitle(title: context.tr('general')),
          _SettingsTile(
            icon: Icons.question_mark_outlined,
            title: context.tr('faq'),
            onTap: () async => await _launchUrl(faqUrl),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: context.tr('terms_of_use'),
            onTap: () async => await _launchUrl(termsUrl),
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: context.tr('privacy_policy'),
            onTap: () async => await _launchUrl(privacyUrl),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: context.tr('about_us'),
            onTap: () async => await _launchUrl(aboutUrl),
          ),
          _SettingsTile(
            icon: Icons.logout_outlined,
            title: context.tr('logout'),
            titleColor: Colors.red,
            onTap: () async => await authProvider.logout(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                '${context.tr('app_version')} $appVersion',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Ayarlar bölüm başlığı widgetı
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Ayarlar liste öğesi widgetı
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;
  final String? subtitle;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.titleColor,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: Colors.grey)) : null,
      onTap: onTap,
    );
  }
}
