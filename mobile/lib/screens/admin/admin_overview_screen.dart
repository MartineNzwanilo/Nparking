import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/theme_provider.dart';
import 'admin_settings_screen.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Executive Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.warning)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.moon, color: AppTheme.warning),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppTheme.warning),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminSettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final metrics = adminProvider.dashboardMetrics;
            final todaysRevenue = metrics?['todaysRevenue'] as num? ?? 0;
            final activeVehicles = metrics?['activeVehicles'] as num? ?? 0;
            final activeStaff = metrics?['activeStaff'] as num? ?? 0;
            final securityAlerts = metrics?['securityAlerts'] as num? ?? 0;

            final formattedRevenue = currencyFormat.format(todaysRevenue);

            return RefreshIndicator(
              onRefresh: () => adminProvider.fetchDashboardMetrics(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Global Revenue Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.warning.withOpacity(0.2), AppTheme.warning.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.globe, color: AppTheme.warning, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'GLOBAL REVENUE TODAY',
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white70
                                      : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          adminProvider.isLoadingMetrics && metrics == null
                              ? const SizedBox(
                                  height: 48,
                                  child: Center(child: CircularProgressIndicator(color: AppTheme.warning)),
                                )
                              : Text(
                                  'TZS $formattedRevenue',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppTheme.warning
                                        : const Color(0xFFB45309),
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(LucideIcons.trendingUp, color: AppTheme.success, size: 12),
                                    SizedBox(width: 4),
                                    Text('+14.5%', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'vs Yesterday across all sites',
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    Text(
                      'LIVE METRICS',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Active Vehicles', '$activeVehicles', LucideIcons.car, context)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricCard('Active Staff', '$activeStaff', LucideIcons.users, context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('AI Alerts', '$securityAlerts', LucideIcons.alertTriangle, context, color: AppTheme.error)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricCard('Avg Process Time', '3.2s', LucideIcons.zap, context, color: AppTheme.success)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, BuildContext context, {Color color = Colors.grey}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color == Colors.grey
                ? (isDark ? Colors.white70 : Colors.black54)
                : color,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}
