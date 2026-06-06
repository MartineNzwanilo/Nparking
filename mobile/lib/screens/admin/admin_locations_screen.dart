import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/global_popup.dart';
import '../../providers/admin_provider.dart';
import '../../providers/shell_navigation_provider.dart';

class AdminLocationsScreen extends StatelessWidget {
  const AdminLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Parking Sites', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plusCircle, color: AppTheme.warning),
            onPressed: () => _showSiteFormDialog(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final sites = adminProvider.sites;

            return RefreshIndicator(
              onRefresh: () => adminProvider.fetchSites(),
              child: sites.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        adminProvider.isLoadingSites
                            ? const Center(child: CircularProgressIndicator(color: AppTheme.warning))
                            : const Center(
                                child: Column(
                                  children: [
                                    Icon(LucideIcons.mapPin, color: Colors.grey, size: 48),
                                    SizedBox(height: 16),
                                    Text('No parking locations configured.', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: sites.length,
                      itemBuilder: (context, index) {
                        final site = sites[index] as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildSiteCard(site, context),
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSiteCard(Map<String, dynamic> site, BuildContext context) {
    final name = site['name'] ?? 'Parking Site';
    final location = site['location'] ?? 'Unknown Location';
    final capacity = (site['capacity'] as num? ?? 0).toInt();
    final totalSessions = site['_count']?['sessions'] ?? 0;
    final staffCount = site['_count']?['users'] ?? 0;

    final occupancyList = site['occupancy'] as List? ?? [];
    int activeCount = 0;
    for (var item in occupancyList) {
      activeCount += (item['count'] as num? ?? 0).toInt();
    }

    final occupancyPercent = capacity > 0 ? (activeCount / capacity * 100).toStringAsFixed(0) : '0';
    final isFull = capacity > 0 && activeCount >= capacity;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFull ? AppTheme.error.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFull ? 'FULL' : '$occupancyPercent% Full',
                  style: TextStyle(color: isFull ? AppTheme.error : AppTheme.success, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(LucideIcons.car, color: AppTheme.warning, size: 16),
              const SizedBox(width: 8),
              Text(
                '$activeCount / $capacity Spaces Occupied',
                style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.users, color: AppTheme.textSecondary(context), size: 16),
              const SizedBox(width: 8),
              Text('$staffCount Watchmen Assigned', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.history, color: AppTheme.textSecondary(context), size: 16),
              const SizedBox(width: 8),
              Text('$totalSessions Total Parking Sessions', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          const SizedBox(height: 8),
          Text(
            'LIVE VEHICLE BREAKDOWN',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          
          // Render Occupancy Breakdown
          if (occupancyList.isEmpty)
            Text('Empty (No vehicles checked in)', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13, fontStyle: FontStyle.italic))
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: occupancyList.map((item) {
                return Chip(
                  label: Text(
                    '${item['count']} ${item['name']}',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.success,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppTheme.success.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppTheme.success.withOpacity(0.3)),
                  ),
                );
              }).toList(),
            ),
            
          const SizedBox(height: 16),
          Divider(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showSiteFormDialog(context, site: site),
                      icon: Icon(LucideIcons.edit3, size: 16, color: AppTheme.textSecondary(context)),
                      label: Text('Edit', style: TextStyle(color: AppTheme.textSecondary(context))),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteSite(context, site),
                      icon: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.error),
                      label: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    final adminProvider = context.read<AdminProvider>();
                    adminProvider.setSelectedSiteIdForSurveillance(site['id']);
                    adminProvider.fetchCameras(siteId: site['id']);
                    context.read<ShellNavigationProvider>().setIndex(2, maxIndex: 6);
                  },
                  icon: const Icon(LucideIcons.video, size: 16, color: AppTheme.primary),
                  label: const Text('Cameras', style: TextStyle(color: AppTheme.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSiteFormDialog(BuildContext context, {Map<String, dynamic>? site}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: site?['name'] ?? '');
    final locationController = TextEditingController(text: site?['location'] ?? '');
    final capacityController = TextEditingController(text: site?['capacity']?.toString() ?? '50');

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppTheme.warning.withOpacity(0.3) : AppTheme.warning.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.warning.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ],
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site == null ? 'CREATE NEW SITE' : 'EDIT SITE DETAILS',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.building, size: 20),
                        labelText: 'Site Name',
                        hintText: 'e.g. Airport Gate A',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: locationController,
                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.mapPin, size: 20),
                        labelText: 'Location',
                        hintText: 'e.g. Terminal 1',
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Location is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: capacityController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.car, size: 20),
                        labelText: 'Capacity',
                        hintText: 'e.g. 100',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Capacity is required';
                        final cap = int.tryParse(value);
                        if (cap == null || cap <= 0) return 'Must be a positive number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary(context),
                              side: BorderSide(
                                color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warning,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final name = nameController.text.trim();
                              final loc = locationController.text.trim();
                              final cap = int.parse(capacityController.text.trim());

                              final adminProvider = context.read<AdminProvider>();
                              try {
                                if (site == null) {
                                  await adminProvider.createSite(name, loc, cap);
                                  if (ctx.mounted) {
                                    GlobalPopup.showSuccess(ctx, 'Site "$name" created successfully.', title: 'CREATED');
                                  }
                                } else {
                                  await adminProvider.updateSite(site['id'], name, loc, cap);
                                  if (ctx.mounted) {
                                    GlobalPopup.showSuccess(ctx, 'Site "$name" updated successfully.', title: 'UPDATED');
                                  }
                                }
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  GlobalPopup.showError(ctx, e.toString().replaceAll('Exception: ', ''), title: 'ERROR');
                                }
                              }
                            },
                            child: Text(site == null ? 'Create' : 'Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteSite(BuildContext context, Map<String, dynamic> site) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.error.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.trash2, color: AppTheme.error, size: 56),
                const SizedBox(height: 24),
                Text(
                  'DELETE SITE',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to delete "${site['name']}"? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary(context),
                          side: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final adminProvider = context.read<AdminProvider>();
                          try {
                            await adminProvider.deleteSite(site['id']);
                            if (ctx.mounted) {
                              GlobalPopup.showSuccess(ctx, 'Site deleted successfully.', title: 'DELETED');
                              Navigator.pop(ctx);
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              GlobalPopup.showError(ctx, e.toString().replaceAll('Exception: ', ''), title: 'FAILED');
                              Navigator.pop(ctx);
                            }
                          }
                        },
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
