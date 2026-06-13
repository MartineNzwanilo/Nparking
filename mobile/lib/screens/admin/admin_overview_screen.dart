import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/theme_provider.dart';
import 'admin_settings_screen.dart';
import '../activity_screen.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // Start periodic background updates every 10 seconds to keep metrics "live"
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        final adminProvider = context.read<AdminProvider>();
        if (!adminProvider.isLoadingMetrics) {
          adminProvider.fetchDashboardMetrics();
        }
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppTheme.primary)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.activity, color: AppTheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActivityScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.moon, color: AppTheme.primary),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.settings, color: AppTheme.primary),
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
            final todaysExpectedRevenue = metrics?['todaysExpectedRevenue'] as num? ?? 0;
            final activeVehicles = metrics?['activeVehicles'] as num? ?? 0;
            final activeStaff = metrics?['activeStaff'] as num? ?? 0;
            final securityAlerts = metrics?['securityAlerts'] as num? ?? 0;
            final freeLodgeParkings = metrics?['freeLodgeParkings'] as num? ?? 0;
            final revenueChangePercent = (metrics?['revenueChangePercent'] as num?)?.toDouble() ?? 0.0;
            final isPositive = revenueChangePercent >= 0;
            final trendColor = isPositive ? AppTheme.success : AppTheme.error;
            final trendText = '${isPositive ? '+' : ''}${revenueChangePercent.toStringAsFixed(1)}%';
            final trendIcon = isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown;

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
                          colors: [AppTheme.primary.withOpacity(0.2), AppTheme.primary.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.globe, color: AppTheme.primary, size: 20),
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
                                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                                )
                              : Text(
                                  'TZS $formattedRevenue',
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppTheme.primary
                                        : AppTheme.primary,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                          if (todaysExpectedRevenue > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              '+ TZS ${currencyFormat.format(todaysExpectedRevenue)} Expected (Unpaid Early Check-Ins)',
                              style: const TextStyle(
                                color: AppTheme.warning,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: trendColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(trendIcon, color: trendColor, size: 12),
                                    const SizedBox(width: 4),
                                    Text(trendText, style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold)),
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
                        Expanded(child: _buildMetricCard('Free Parkings', '$freeLodgeParkings', LucideIcons.parkingSquare, context, color: AppTheme.success)),
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
      width: double.infinity,
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
