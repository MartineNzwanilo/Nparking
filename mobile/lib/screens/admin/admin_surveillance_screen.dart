import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
              onRefresh: () => adminProvider.fetchCameras(siteId: adminProvider.selectedSiteIdForSurveillance),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text('LIVE CCTV FEEDS', style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12)),
                  const SizedBox(height: 12),
                  
                  if (adminProvider.selectedSiteIdForSurveillance != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cameras.isNotEmpty
                                  ? 'Showing cameras for ${cameras.first['site']?['name'] ?? 'selected site'}'
                                  : 'Showing cameras for selected site',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              adminProvider.setSelectedSiteIdForSurveillance(null);
                              adminProvider.fetchCameras();
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'Show All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
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
                        child: CctvCameraFeed(
                          title: '$name ($siteName)',
                          isLive: isActive,
                        ),
                      );
                    }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CctvCameraFeed extends StatefulWidget {
  final String title;
  final bool isLive;

  const CctvCameraFeed({
    super.key,
    required this.title,
    required this.isLive,
  });

  @override
  State<CctvCameraFeed> createState() => _CctvCameraFeedState();
}

class _CctvCameraFeedState extends State<CctvCameraFeed> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _opacityAnimation;
  late Timer _timer;
  String _timeString = '';

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(_blinkController);
    
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final formatted = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    if (mounted) {
      setState(() {
        _timeString = formatted;
      });
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          ),
          child: Stack(
            children: [
              // Simulated scanlines/grid overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: CameraGridPainter(),
                ),
              ),
              
              // Viewfinder corners
              Positioned.fill(
                child: CustomPaint(
                  painter: ViewfinderPainter(color: Colors.white.withOpacity(0.35)),
                ),
              ),
              
              // Camera status/signal icon in the center
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.video,
                      color: Colors.white.withOpacity(0.15),
                      size: 56,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CCTV SIGNAL STABLE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.12),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Top Overlay: Status and Specs
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge (LIVE / STANDBY)
                    Row(
                      children: [
                        if (widget.isLive)
                          FadeTransition(
                            opacity: _opacityAnimation,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        Text(
                          widget.isLive ? 'REC • LIVE' : 'STANDBY',
                          style: TextStyle(
                            color: widget.isLive ? AppTheme.error : Colors.grey[400],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    // Resolution & Wifi Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '1080P',
                            style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.wifi, color: AppTheme.success, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Bottom Overlay: Camera name and Time stamp
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _timeString,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1.0;

    // Draw horizontal scanlines
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ViewfinderPainter extends CustomPainter {
  final Color color;
  ViewfinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const length = 12.0;
    const margin = 12.0;

    // Top Left
    canvas.drawLine(const Offset(margin, margin), const Offset(margin + length, margin), paint);
    canvas.drawLine(const Offset(margin, margin), const Offset(margin, margin + length), paint);

    // Top Right
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin - length, margin), paint);
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin, margin + length), paint);

    // Bottom Left
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + length, size.height - margin), paint);
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin, size.height - margin - length), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin - length, size.height - margin), paint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - length), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
