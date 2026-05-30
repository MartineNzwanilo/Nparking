import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';

class AdminSurveillanceScreen extends StatelessWidget {
  const AdminSurveillanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Live Surveillance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: SafeArea(
        child: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            final cameras = adminProvider.cameras;

            final isDark = Theme.of(context).brightness == Brightness.dark;
            return RefreshIndicator(
              onRefresh: () => adminProvider.fetchCameras(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text('LIVE CCTV FEEDS', style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12)),
                  const SizedBox(height: 12),
                  
                  if (adminProvider.isLoadingCameras && cameras.isEmpty)
                    const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator(color: AppTheme.warning)),
                    )
                  else if (cameras.isEmpty)
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Text(
                        'No CCTV cameras configured',
                        style: TextStyle(color: AppTheme.textSecondary(context)),
                      ),
                    )
                  else
                    ...cameras.map((camera) {
                      final name = camera['name'] ?? 'CCTV Camera';
                      final siteName = camera['site']?['name'] ?? 'Unassigned Site';
                      final isActive = camera['isActive'] == true;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCameraFeed('$name ($siteName)', isActive, context),
                      );
                    }).toList(),
                  
                  const SizedBox(height: 16),
                  Text('RECENT AUDITS (PHOTO VERIFICATION)', style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildAuditCard('T123 ABC', 'Bodaboda', 'Main Branch', true, context),
                  const SizedBox(height: 12),
                  _buildAuditCard('T999 ZYX', 'Lorry', 'Airport', false, context), // Mock a failure
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCameraFeed(String title, bool isLive, BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          const Center(child: Icon(LucideIcons.video, color: Colors.white24, size: 64)),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLive ? AppTheme.error.withOpacity(0.8) : Colors.grey.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (isLive) const Icon(Icons.circle, color: Colors.white, size: 8),
                  if (isLive) const SizedBox(width: 4),
                  Text(isLive ? 'LIVE' : 'OFFLINE', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditCard(String plate, String type, String site, bool passed, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: passed ? AppTheme.success.withOpacity(0.3) : AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.image,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plate,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Logged as: $type',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                Text(
                  site,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context).withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(passed ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: passed ? AppTheme.success : AppTheme.error),
        ],
      ),
    );
  }
}
