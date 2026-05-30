import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/theme_provider.dart';
import '../services/sync_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vehicles = context.watch<VehicleProvider>().vehicles;
    final activities = context.watch<ActivityProvider>().activities;
    final fullName = auth.name?.trim().isNotEmpty == true ? auth.name! : context.t.tr('gateOperator');
    final initials = _initials(fullName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title Header (Tesla-style)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.t.tr('myProfile').toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Premium Profile Hero Box (Tesla/Uber Inspired)
              Center(
                child: Column(
                  children: [
                    // Centered initials avatar
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      auth.role == 'ADMIN'
                          ? context.t.tr('systemAdministrator')
                          : context.t.tr('gateOperator'),
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                      const SizedBox(height: 10),
                      Consumer<SyncService>(
                        builder: (context, syncService, child) {
                          IconData syncIcon;
                          Color syncColor;
                          String syncText;
                          bool isSyncing = false;

                          switch (syncService.status) {
                            case SyncStatus.synced:
                              syncIcon = LucideIcons.checkCircle;
                              syncColor = Colors.green;
                              syncText = context.t.tr('synced');
                              break;
                            case SyncStatus.syncing:
                              syncIcon = LucideIcons.refreshCw;
                              syncColor = Colors.blue;
                              syncText = context.t.tr('syncing');
                              isSyncing = true;
                              break;
                            case SyncStatus.pending:
                              syncIcon = LucideIcons.cloudOff;
                              syncColor = Colors.orange;
                              syncText = '${syncService.pendingCount} ${context.t.tr('pendingSync')}';
                              break;
                            case SyncStatus.offline:
                              syncIcon = LucideIcons.wifiOff;
                              syncColor = Colors.red;
                              syncText = context.t.tr('offline');
                              break;
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: syncColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: syncColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                isSyncing
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: syncColor,
                                        ),
                                      )
                                    : Icon(syncIcon, color: syncColor, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  syncText,
                                  style: TextStyle(
                                    color: syncColor, 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // Uber-Style Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      context.t.tr('vehicles'), 
                      '${vehicles.length}', 
                      LucideIcons.car,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      context.t.tr('activity'), 
                      '${activities.length}', 
                      LucideIcons.activity,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Settings list container (Tesla style)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
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
                    Divider(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05), 
                      height: 1,
                    ),
                    _buildActionTile(
                      context,
                      LucideIcons.printer,
                      context.t.tr('printerSettings'),
                      context.t.tr('viewPrinterStatus'),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.t.tr('printerStatus'),
                                    style: TextStyle(
                                      color: AppTheme.textPrimary(context),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    context.t.tr('printerReady'),
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.t.tr('printerConnectionReady'),
                                    style: TextStyle(
                                      color: AppTheme.textSecondary(context),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: () {
                                        final ticket = [
                                          context.t.tr('receiptTitle'),
                                          context.t.tr('printerReady'),
                                          context.t.tr('printerConnectionReady'),
                                          '${context.t.tr('roleLabel')}: ${auth.role ?? context.t.tr('gateOperator')}',
                                          '${context.t.tr('siteLabel')}: ${auth.siteId ?? context.t.tr('unassigned')}',
                                        ].join('\n');
                                        Clipboard.setData(ClipboardData(text: ticket));
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(context.t.tr('testTicketCopied'))),
                                        );
                                      },
                                      child: Text(
                                        context.t.tr('copyTestTicket'),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Divider(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05), 
                      height: 1,
                    ),
                    _buildActionTile(
                      context,
                      LucideIcons.moon,
                      context.t.tr('darkMode'),
                      context.t.tr('tapToSwitch'),
                      onTap: () => context.read<ThemeProvider>().toggleTheme(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Clean Simplified Logout Button (As Requested: LOGOUT IS ENOUGH)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error.withOpacity(0.12),
                    foregroundColor: AppTheme.error,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    context.read<AuthProvider>().logout();
                  },
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  label: Text(
                    context.t.tr('logOutBoss'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontSize: 14,
                    ),
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

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'SP';
    if (parts.length == 1) {
      final value = parts.first;
      return value.length >= 2
          ? value.substring(0, 2).toUpperCase()
          : value.substring(0, 1).toUpperCase();
    }
    final first = parts.first.isNotEmpty ? parts.first[0] : 'S';
    final last = parts.last.isNotEmpty ? parts.last[0] : 'P';
    return (first + last).toUpperCase();
  }
}
