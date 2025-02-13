import 'package:flutter/material.dart';
import 'package:palseapp/core/provider/auth_provider.dart';
import 'package:palseapp/features/settings/view/edit_profile.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          const _SectionTitle(title: 'Kullanıcı'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Profil',
            trailing: authProvider.user?.verification == false
                ? const Text(
                    'Hesabın Onaylı Değil',
                    style: TextStyle(color: Colors.red),
                  )
                : const Text(
                    'Hesabın Onaylı',
                    style: TextStyle(color: Colors.green),
                  ),
          ),
          const _SectionTitle(title: 'Uygulama'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Bildirimler',
          ),
          const _SectionTitle(title: 'Genel'),
          _SettingsTile(
            icon: Icons.question_mark_outlined,
            title: 'Sıkça Sorulan Sorular',
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Kullanım Şartları',
          ),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: 'Gizlilik Politikası',
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Hakkımızda',
          ),
          _SettingsTile(
            icon: Icons.logout_outlined,
            title: 'Çıkış Yap',
            titleColor: Colors.red,
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Uygulama Versiyonu v.1.1.2',
                style: TextStyle(
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

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: Navigate to respective pages
        Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileView(user: user!)));
      },
    );
  }
}
