import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/sync_service.dart';
import '../core/database_helper.dart';
import 'printer_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeProvider = context.watch<LocaleProvider>();
    final currentLocale = localeProvider.locale?.languageCode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Header
              Text(
                'SETTINGS',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 24),

              Material(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildActionTile(
                        context,
                        LucideIcons.refreshCw,
                        context.t.tr('syncOfflineData'),
                        context.t.tr('refreshLiveWatchmanData'),
                        onTap: () async {
                          final syncService = context.read<SyncService>();
                          if (syncService.status == SyncStatus.offline) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(context.t.tr('offline'))),
                             );
                             return;
                          }
                          await syncService.syncPendingQueue();
                          await Future.wait([
                            context.read<VehicleProvider>().fetchVehicles(),
                            context.read<ActivityProvider>().fetchActivities(),
                          ]);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.t.tr('watchmanDataSynced'))),
                          );
                        },
                      ),
                      _divider(isDark),
                      _buildActionTile(
                        context,
                        LucideIcons.trash2,
                        'Clear App Cache',
                        'Remove all offline stored data',
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              bool isClearing = false;
                              return StatefulBuilder(
                                builder: (context, setStateDialog) => AlertDialog(
                                  title: const Text('Clear App Cache'),
                                  content: const Text('This will delete all offline data and pending syncs. Proceed?'),
                                  actions: [
                                    TextButton(onPressed: isClearing ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: isClearing ? null : () async {
                                        setStateDialog(() => isClearing = true);
                                        await DatabaseHelper.instance.clearAll();
                                        if (context.mounted) Navigator.pop(context, true);
                                      }, 
                                      child: isClearing
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                                          : const Text('Clear', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          );
                          if (confirmed == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('App cache cleared successfully!')),
                            );
                            context.read<VehicleProvider>().fetchVehicles();
                            context.read<ActivityProvider>().fetchActivities();
                          }
                        },
                      ),
                      _divider(isDark),
                      _buildActionTile(
                        context,
                        LucideIcons.printer,
                        context.t.tr('printerSettings'),
                        'Configure Network & Bluetooth Printers',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PrinterSettingsScreen()),
                          );
                        },
                      ),
                      _divider(isDark),
                      _buildSwitchTile(
                        context,
                        LucideIcons.printer,
                        'Auto-Print Entry Ticket',
                        'Instantly print QR slip on check-in',
                        auth.autoPrint,
                        (val) => auth.updatePreferences(autoPrint: val),
                      ),
                      _divider(isDark),
                      _buildSwitchTile(
                        context,
                        LucideIcons.mail,
                        'Auto-Send Email Ticket',
                        'Deliver HTML receipts to drivers',
                        auth.autoSendEmail,
                        (val) => auth.updatePreferences(autoSendEmail: val),
                      ),
                      _divider(isDark),
                      _buildSwitchTile(
                        context,
                        LucideIcons.messageSquare,
                        'Auto-Send Beem SMS',
                        'Send dynamic details via Beem Africa',
                        auth.autoSendSms,
                        (val) => auth.updatePreferences(autoSendSms: val),
                      ),
                      _divider(isDark),
                      _buildActionTile(
                        context,
                        LucideIcons.moon,
                        context.t.tr('darkMode'),
                        context.t.tr('tapToSwitch'),
                        onTap: () => context.read<ThemeProvider>().toggleTheme(),
                      ),
                      _divider(isDark),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(LucideIcons.languages, color: AppTheme.textPrimary(context), size: 20),
                        ),
                        title: Text(
                          context.t.tr('language'),
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          context.t.tr('chooseLanguage'),
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: currentLocale ?? 'en',
                            dropdownColor: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
                            icon: Icon(LucideIcons.chevronDown, size: 16, color: AppTheme.textSecondary(context)),
                            items: const [
                              DropdownMenuItem(value: 'en', child: Text('English')),
                              DropdownMenuItem(value: 'sw', child: Text('Kiswahili')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                localeProvider.setLocale(Locale(val));
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05), 
      height: 1,
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.textPrimary(context), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textPrimary(context),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondary(context),
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: AppTheme.textSecondary(context).withOpacity(0.5),
        size: 18,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.textPrimary(context), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textPrimary(context),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondary(context),
          fontSize: 12,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: AppTheme.primary,
        onChanged: onChanged,
      ),
    );
  }
}
