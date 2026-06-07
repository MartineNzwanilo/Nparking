import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/shell_navigation_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/admin_provider.dart';
import 'settings_screen.dart';
import 'admin/admin_expense_screen.dart';
import 'admin/admin_locations_screen.dart';
import 'admin/admin_overview_screen.dart';
import 'admin/admin_reports_screen.dart';
import 'admin/admin_settings_screen.dart';
import 'admin/admin_surveillance_screen.dart';
import 'admin/admin_vehicles_screen.dart';
import 'checkin_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'vehicles_screen.dart';
import '../widgets/custom_bottom_bar.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<VehicleProvider>().fetchVehicles();
      context.read<ActivityProvider>().fetchActivities();
      if (auth.isAdmin) {
        context.read<AdminProvider>().fetchDashboardMetrics();
        context.read<AdminProvider>().fetchCameras();
        context.read<AdminProvider>().fetchSites();
      }
    });
  }

  List<Widget> _watchmanScreens() => const [
        DashboardScreen(),
        VehiclesScreen(),
        CheckInScreen(),
        SettingsScreen(),
        ProfileScreen(),
      ];

  List<Widget> _adminScreens() => const [
        AdminOverviewScreen(),
        AdminLocationsScreen(),
        AdminSurveillanceScreen(),
        AdminExpenseScreen(), // Replaced Activity with Expenses
        AdminReportsScreen(),
        AdminVehiclesScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ShellNavigationProvider>(
      builder: (context, auth, nav, child) {
        final tabs = auth.isAdmin ? _adminScreens() : _watchmanScreens();
        final effectiveIndex =
            nav.currentIndex.clamp(0, tabs.length - 1).toInt();

        if (effectiveIndex != nav.currentIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context
                  .read<ShellNavigationProvider>()
                  .setIndex(0, maxIndex: tabs.length - 1);
            }
          });
        }

        return Scaffold(
          body: IndexedStack(
            index: effectiveIndex,
            children: tabs,
          ),
          bottomNavigationBar: CustomSimBottomNavBar(
            currentIndex: effectiveIndex,
            isAdmin: auth.isAdmin,
            shellContext: context,
            onTap: (index) {
              context
                  .read<ShellNavigationProvider>()
                  .setIndex(index, maxIndex: tabs.length - 1);
              if (auth.isAdmin && index == 0) {
                // Refresh dashboard metrics immediately on tab switch
                context.read<AdminProvider>().fetchDashboardMetrics();
              } else if (auth.isAdmin && index == 2) {
                // Reset site filter and fetch all cameras when navigating via bottom bar
                final adminProvider = context.read<AdminProvider>();
                adminProvider.setSelectedSiteIdForSurveillance(null);
                adminProvider.fetchCameras();
              }
            },
          ),
        );
      },
    );
  }
}
