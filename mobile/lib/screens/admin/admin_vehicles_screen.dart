import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/vehicle_provider.dart';

class AdminVehiclesScreen extends StatefulWidget {
  const AdminVehiclesScreen({super.key});

  @override
  State<AdminVehiclesScreen> createState() => _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends State<AdminVehiclesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().fetchVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmToggleBlacklist(Map<String, dynamic> vehicle) {
    final isBlacklisted = vehicle['isBlacklisted'] ?? false;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBlacklisted ? 'Remove from Blacklist?' : 'Add to Blacklist?'),
        content: Text(
          isBlacklisted
              ? 'Are you sure you want to whitelist vehicle ${vehicle['plateNumber']}?'
              : 'Are you sure you want to blacklist vehicle ${vehicle['plateNumber']}? Blacklisted vehicles will trigger alarms on entry.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlacklisted ? AppTheme.success : AppTheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<VehicleProvider>().toggleBlacklist(vehicle['id'], isBlacklisted);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBlacklisted
                            ? 'Vehicle ${vehicle['plateNumber']} whitelisted successfully.'
                            : 'Vehicle ${vehicle['plateNumber']} blacklisted successfully.'
                      ),
                      backgroundColor: isBlacklisted ? AppTheme.success : AppTheme.error,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update blacklist status.')),
                  );
                }
              }
            },
            child: Text(isBlacklisted ? 'WHITELIST' : 'BLACKLIST', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showVehiclePreview(BuildContext context, Map<String, dynamic> vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<VehicleProvider>(
          builder: (context, provider, child) {
            // Retrieve current live vehicle state from provider list
            final currentVehicle = provider.vehicles.firstWhere(
              (v) => v['id'] == vehicle['id'],
              orElse: () => vehicle,
            );
            final curIsInside = currentVehicle['sessions'] != null &&
                currentVehicle['sessions'].isNotEmpty &&
                currentVehicle['sessions'][0]['status'] == 'INSIDE';
            final curLatestSession = currentVehicle['sessions'] != null && currentVehicle['sessions'].isNotEmpty
                ? currentVehicle['sessions'][0]
                : null;
            final curIsBlacklisted = currentVehicle['isBlacklisted'] ?? false;

            IconData icon = LucideIcons.car;
            final catName = currentVehicle['category']?['name'] ?? 'Sedan/SUV';
            if (catName == 'Bodaboda') icon = Icons.motorcycle_outlined;
            else if (catName == 'Bajaji') icon = Icons.electric_rickshaw_outlined;
            else if (catName == 'Lorry') icon = Icons.local_shipping_outlined;
            else if (catName == 'Daladala') icon = Icons.directions_bus_outlined;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(
                  color: curIsBlacklisted
                      ? AppTheme.error.withOpacity(0.3)
                      : AppTheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: curIsBlacklisted
                                    ? AppTheme.error.withOpacity(0.1)
                                    : AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: curIsBlacklisted ? AppTheme.error : AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentVehicle['plateNumber'] ?? 'UNKNOWN',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: curIsBlacklisted ? AppTheme.error : AppTheme.textPrimary(context),
                                      letterSpacing: 1.0,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    currentVehicle['category']?['name'] ?? 'Unknown Category',
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: curIsInside ? AppTheme.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: curIsInside ? AppTheme.success.withOpacity(0.3) : Colors.transparent),
                        ),
                        child: Text(
                          curIsInside ? 'Parked Inside' : 'Absent',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: curIsInside ? AppTheme.success : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Theme.of(context).dividerColor.withOpacity(0.15)),
                  const SizedBox(height: 16),
                  
                  // Metadata scroll
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (curIsInside && curLatestSession != null) ...[
                            _buildStatusSection(curLatestSession),
                            const SizedBox(height: 24),
                          ],

                          const Text(
                            'OWNER & CONTACT INFO',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(LucideIcons.user, 'Full Name', currentVehicle['ownerName'] ?? '—'),
                          _buildDetailRow(LucideIcons.phone, 'Phone Number', currentVehicle['phone'] ?? '—'),
                          _buildDetailRow(LucideIcons.building, 'Company', currentVehicle['company'] ?? '—'),
                          
                          const SizedBox(height: 24),
                          const Text(
                            'VEHICLE SPECIFICS',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildColorRow(currentVehicle['color'] ?? '—'),
                          _buildDetailRow(LucideIcons.car, 'Make / Model', currentVehicle['makeModel'] ?? '—'),
                          
                          const SizedBox(height: 24),
                          const Text(
                            'VEHICLE PHOTOS',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildPhotoPlaceholder('Front View')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildPhotoPlaceholder('License Plate')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildPhotoPlaceholder('Side/Back')),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: curIsBlacklisted
                                ? AppTheme.success.withOpacity(0.15)
                                : AppTheme.error.withOpacity(0.15),
                            foregroundColor: curIsBlacklisted ? AppTheme.success : AppTheme.error,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: curIsBlacklisted
                                    ? AppTheme.success.withOpacity(0.4)
                                    : AppTheme.error.withOpacity(0.4),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: Icon(curIsBlacklisted ? LucideIcons.shieldCheck : LucideIcons.ban, size: 18),
                          label: Text(
                            curIsBlacklisted ? 'WHITELIST VEHICLE' : 'BLACKLIST VEHICLE',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmToggleBlacklist(currentVehicle);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context).dividerColor.withOpacity(0.05),
                          foregroundColor: AppTheme.textSecondary(context),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusSection(Map<String, dynamic> session) {
    final checkInStr = session['checkIn'] as String;
    String formattedTime = '—';
    try {
      final checkInTime = DateTime.parse(checkInStr);
      formattedTime = DateFormat('MMM dd, yyyy · hh:mm a').format(checkInTime);
    } catch (_) {}
    
    final siteName = session['site'] != null ? session['site']['name'] ?? '—' : '—';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PARKING STATUS',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.success, letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Text(
            'Parked at: $siteName',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
          ),
          const SizedBox(height: 2),
          Text(
            'Checked in: $formattedTime',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String colorName) {
    Color? displayColor;
    final cleanedName = colorName.trim().toLowerCase();
    if (cleanedName == 'white') displayColor = Colors.white;
    else if (cleanedName == 'black') displayColor = Colors.black;
    else if (cleanedName == 'silver') displayColor = Colors.grey[400];
    else if (cleanedName == 'grey' || cleanedName == 'gray') displayColor = Colors.grey[700];
    else if (cleanedName == 'red') displayColor = Colors.red;
    else if (cleanedName == 'blue') displayColor = Colors.blue;
    else if (cleanedName == 'green') displayColor = Colors.green;
    else if (cleanedName == 'yellow') displayColor = Colors.yellow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(LucideIcons.palette, color: Colors.grey, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VEHICLE COLOR',
                  style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (displayColor != null) ...[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: displayColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3), width: 1),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      colorName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(String label) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.camera, color: Colors.grey.withOpacity(0.6), size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.withOpacity(0.8), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Global Vehicles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () => context.read<VehicleProvider>().fetchVehicles(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Consumer<VehicleProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.vehicles.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }

            final filteredList = provider.vehicles.where((v) {
              final q = _searchQuery.toLowerCase();
              bool matchesSearch = q.isEmpty || 
                  (v['plateNumber']?.toLowerCase().contains(q) ?? false) ||
                  (v['ownerName']?.toLowerCase().contains(q) ?? false) ||
                  (v['phone']?.toLowerCase().contains(q) ?? false);
              return matchesSearch;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.inbox, size: 64, color: Colors.grey.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              const Text(
                                "No vehicles found.",
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.fetchVehicles(),
                          child: ListView.separated(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 80),
                            itemCount: filteredList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _buildVehicleCard(filteredList[index]);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppTheme.textPrimary(context)),
        decoration: InputDecoration(
          prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.grey, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          hintText: 'Search Plate globally...',
          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle) {
    bool isInside = vehicle['sessions'] != null &&
        vehicle['sessions'].isNotEmpty &&
        vehicle['sessions'][0]['status'] == 'INSIDE';
    
    final latestSession = vehicle['sessions'] != null && vehicle['sessions'].isNotEmpty
        ? vehicle['sessions'][0]
        : null;
    final siteName = latestSession != null && latestSession['site'] != null
        ? latestSession['site']['name'] ?? 'Main'
        : 'Main';
    final statusText = isInside ? 'Inside ($siteName)' : 'Absent';
    bool isBlacklisted = vehicle['isBlacklisted'] ?? false;
    
    IconData icon = LucideIcons.car;
    final catName = vehicle['category']?['name'] ?? 'Sedan/SUV';
    if (catName == 'Bodaboda') icon = Icons.motorcycle_outlined;
    else if (catName == 'Bajaji') icon = Icons.electric_rickshaw_outlined;
    else if (catName == 'Lorry') icon = Icons.local_shipping_outlined;
    else if (catName == 'Daladala') icon = Icons.directions_bus_outlined;

    return GestureDetector(
      onTap: () => _showVehiclePreview(context, vehicle),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBlacklisted
                ? AppTheme.error.withOpacity(0.3)
                : Theme.of(context).dividerColor.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isBlacklisted
                        ? AppTheme.error.withOpacity(0.1)
                        : AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: isBlacklisted ? AppTheme.error : AppTheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vehicle['plateNumber'] ?? 'UNKNOWN',
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 1.0, 
                                color: isBlacklisted ? AppTheme.error : AppTheme.textPrimary(context),
                                decoration: isBlacklisted ? TextDecoration.lineThrough : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle['ownerName'] ?? 'No Owner',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInside ? AppTheme.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isInside ? AppTheme.success : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            Divider(color: Theme.of(context).dividerColor.withOpacity(0.15)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isBlacklisted ? Colors.white : AppTheme.error,
                      backgroundColor: isBlacklisted ? AppTheme.error.withOpacity(0.8) : Colors.transparent,
                      side: BorderSide(color: isBlacklisted ? Colors.transparent : AppTheme.error.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(isBlacklisted ? LucideIcons.shieldCheck : LucideIcons.ban, size: 16),
                    label: Text(
                      isBlacklisted ? 'REMOVE BLACKLIST' : 'BLACKLIST',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    onPressed: () => _confirmToggleBlacklist(vehicle),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
