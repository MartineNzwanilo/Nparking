import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/parking_i18n.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import 'admin_watchmen_screen.dart';
import 'admin_access_logs_screen.dart';
import 'admin_notification_settings_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final localeProv = context.watch<LocaleProvider>();

    final name = auth.name?.isNotEmpty == true ? auth.name! : 'System Administrator';
    final phone = auth.phone ?? 'admin@parking.com';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t.tr('adminSettings'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Admin Profile Header
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.warning.withOpacity(0.15),
                  child: const Icon(LucideIcons.shield, color: AppTheme.warning, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(phone, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            Text(context.t.tr('staffManagement'), style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12)),
            const SizedBox(height: 12),
            _buildActionCard(
              title: context.t.tr('manageWatchmen'),
              subtitle: context.t.tr('manageWatchmenDesc'),
              icon: LucideIcons.users,
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminWatchmenScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              title: context.t.tr('accessLogs'),
              subtitle: context.t.tr('accessLogsDesc'),
              icon: LucideIcons.history,
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminAccessLogsScreen()),
                );
              },
            ),

            const SizedBox(height: 32),
            Text('SYSTEM CONFIGURATION', style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12)),
            const SizedBox(height: 12),
            _buildActionCard(
              title: 'Notification Settings',
              subtitle: 'Configure email SMTP server, WhatsApp, and Twilio SMS',
              icon: LucideIcons.bell,
              context: context,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminNotificationSettingsScreen()),
                );
              },
            ),

            const SizedBox(height: 32),
            Text(context.t.tr('systemPreferences'), style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12)),
            const SizedBox(height: 12),
            
            // Theme Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.moon, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(context.t.tr('darkMode'), style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Switch(
                    value: themeProv.themeMode == ThemeMode.dark,
                    activeColor: AppTheme.warning,
                    onChanged: (value) {
                      themeProv.toggleTheme();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Language Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(LucideIcons.globe, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.t.tr('language'), style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(context.t.tr('chooseLanguage'), style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11)),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                    value: localeProv.locale?.languageCode ?? 'en',
                    style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'sw', child: Text('Kiswahili')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        localeProv.setLocale(Locale(val));
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(LucideIcons.logOut),
                label: Text(context.t.tr('logOutBoss'), style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12)),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: Theme.of(context).textTheme.bodyMedium?.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
