import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';
import '../core/global_popup.dart';
import '../providers/vehicle_provider.dart';
import '../providers/shell_navigation_provider.dart';
import '../core/checkout_helper.dart';
import '../screens/scanner_screen.dart';


class CustomSimBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isAdmin;
  final BuildContext shellContext;

  const CustomSimBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isAdmin,
    required this.shellContext,
  });

  @override
  State<CustomSimBottomNavBar> createState() => _CustomSimBottomNavBarState();
}

class _CustomSimBottomNavBarState extends State<CustomSimBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Colors
    final backgroundColor = isDark 
        ? Colors.black.withOpacity(0.85) 
        : Colors.white.withOpacity(0.90);
    final borderColor = isDark 
        ? Colors.white.withOpacity(0.08) 
        : Colors.black.withOpacity(0.05);
    final shadowColor = isDark 
        ? Colors.black.withOpacity(0.5) 
        : Colors.black.withOpacity(0.08);

    // Watchman tabs: Dashboard(0), Vehicles(1), CheckIn(2, center), Activity(3), Profile(4)
    if (widget.isAdmin) {
      // Admin bottom navigation (6 tabs, simpler flat sleek look without notch)
      return Container(
        height: 74,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAdminTab(0, LucideIcons.layoutDashboard, context.t.tr('dashboard')),
                _buildAdminTab(1, LucideIcons.mapPin, context.t.tr('locations')),
                _buildAdminTab(2, LucideIcons.camera, context.t.tr('surveillance')),
                _buildAdminTab(3, LucideIcons.activity, context.t.tr('activity')),
                _buildAdminTab(4, LucideIcons.fileSpreadsheet, context.t.tr('reports')),
                _buildAdminTab(5, LucideIcons.car, context.t.tr('vehicles')),
              ],
            ),
          ),
        ),
      );
    }

    // Watchman curved SimBanking navigation bar
    return SizedBox(
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background notched shape with blur
          Positioned.fill(
            child: CustomPaint(
              painter: BottomBarPainter(
                color: backgroundColor,
                shadowColor: shadowColor,
                borderColor: borderColor,
              ),
            ),
          ),
          
          // Blur filter (applied to the shape area)
          Positioned.fill(
            child: ClipPath(
              clipper: BottomBarClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Icons Row
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            top: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _buildWatchmanTab(0, LucideIcons.layoutDashboard, widget.shellContext.t.tr('dashboard'))),
                Expanded(child: _buildWatchmanTab(1, LucideIcons.car, widget.shellContext.t.tr('vehicles'))),
                const Expanded(child: SizedBox()), // Center spacing for floating button
                Expanded(child: _buildWatchmanTab(3, LucideIcons.activity, widget.shellContext.t.tr('activity'))),
                Expanded(child: _buildWatchmanTab(4, LucideIcons.user, widget.shellContext.t.tr('myProfile'))),
              ],
            ),
          ),

          // Live Pulsing CheckIn Button
          Positioned(
            top: -16,
            left: 0,
            right: 0,
            child: Center(
              child: _buildLiveCenterButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTab(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;
    final activeColor = AppTheme.primary;
    final unselectedColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => widget.onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : unselectedColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? activeColor : unselectedColor,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchmanTab(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;
    final unselectedColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4) ?? Colors.grey;

    // Custom gradient mapping for selected states
    final List<Gradient> tabGradients = [
      const LinearGradient(
        colors: [Color(0xFF00FF87), Color(0xFF60EFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Colors.transparent, Colors.transparent], // Spacer dummy
      ),
      const LinearGradient(
        colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      const LinearGradient(
        colors: [Color(0xFFFFE259), Color(0xFFFFA751)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ];

    // Colored labels mapping for selected states
    final List<Color> activeLabelColors = [
      const Color(0xFF00D27a), // Dashboard - Emerald Green
      const Color(0xFF0091FF), // Vehicles - Deep Cyan/Blue
      Colors.transparent,       // Spacer dummy
      const Color(0xFFFF3366), // Activity - Neon Red/Pink
      const Color(0xFFFFA000), // Profile - Amber Gold
    ];

    final Color activeAccentColor = isSelected ? activeLabelColors[index] : unselectedColor;

    // Premium grayscale color filter that preserves transparency
    const double r = 0.2126;
    const double g = 0.7152;
    const double b = 0.0722;
    const ColorFilter grayscaleFilter = ColorFilter.matrix(<double>[
      r, g, b, 0, 0,
      r, g, b, 0, 0,
      r, g, b, 0, 0,
      0, 0, 0, 1, 0,
    ]);

    // Build the icon widget (either PNG image asset or vector icon)
    Widget iconWidget;
    if (index == 0) {
      iconWidget = isSelected
          ? Image.asset(
              'assets/images/dashboard_icon.png',
              width: 32,
              height: 32,
            )
          : ColorFiltered(
              colorFilter: grayscaleFilter,
              child: Image.asset(
                'assets/images/dashboard_icon.png',
                width: 32,
                height: 32,
                opacity: const AlwaysStoppedAnimation(0.70),
              ),
            );
    } else if (index == 1) {
      iconWidget = isSelected
          ? Image.asset(
              'assets/images/vehicles_icon.png',
              width: 32,
              height: 32,
            )
          : ColorFiltered(
              colorFilter: grayscaleFilter,
              child: Image.asset(
                'assets/images/vehicles_icon.png',
                width: 32,
                height: 32,
                opacity: const AlwaysStoppedAnimation(0.70),
              ),
            );
    } else if (index == 3) {
      iconWidget = isSelected
          ? Image.asset(
              'assets/images/activity_icon.png',
              width: 32,
              height: 32,
            )
          : ColorFiltered(
              colorFilter: grayscaleFilter,
              child: Image.asset(
                'assets/images/activity_icon.png',
                width: 32,
                height: 32,
                opacity: const AlwaysStoppedAnimation(0.70),
              ),
            );
    } else if (index == 4) {
      iconWidget = isSelected
          ? Image.asset(
              'assets/images/profile_icon.png',
              width: 32,
              height: 32,
            )
          : ColorFiltered(
              colorFilter: grayscaleFilter,
              child: Image.asset(
                'assets/images/profile_icon.png',
                width: 32,
                height: 32,
                opacity: const AlwaysStoppedAnimation(0.70),
              ),
            );
    } else {
      iconWidget = isSelected
          ? ShaderMask(
              shaderCallback: (bounds) => tabGradients[index].createShader(bounds),
              child: Icon(
                icon,
                color: Colors.white,
                size: 26,
              ),
            )
          : Icon(
              icon,
              color: unselectedColor,
              size: 26,
            );
    }

    return InkWell(
      onTap: () => widget.onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? activeAccentColor.withOpacity(0.08) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: activeAccentColor.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: iconWidget,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: activeAccentColor,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCenterButton() {
    final isSelected = widget.currentIndex == 2;

    return GestureDetector(
      onTap: () => _showScanOptionBottomSheet(context),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse rings
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 58 + (_pulseController.value * 18),
                      height: 58 + (_pulseController.value * 18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withOpacity((1.0 - _pulseController.value) * 0.5),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 58 + ((_pulseController.value + 0.5) % 1.0 * 18),
                      height: 58 + ((_pulseController.value + 0.5) % 1.0 * 18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withOpacity((1.0 - ((_pulseController.value + 0.5) % 1.0)) * 0.3),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            // Glowing solid ring background
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.8),
                    isSelected ? AppTheme.primary.withOpacity(0.85) : AppTheme.primary.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(isSelected ? 0.5 : 0.3),
                    blurRadius: isSelected ? 16 : 10,
                    spreadRadius: isSelected ? 3 : 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.scanLine,
                color: Colors.white,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showScanOptionBottomSheet(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161618) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'CHOOSE SCAN ACTION',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              
              _buildOptionCard(
                context: context,
                title: 'Check In Vehicle',
                subtitle: 'Scan License Plate (OCR)',
                icon: LucideIcons.scanLine,
                color: AppTheme.success,
                onTap: () async {
                  Navigator.pop(context);
                  final status = await Permission.camera.request();
                  if (status.isGranted) {
                    if (!mounted) return;
                    final plate = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScannerScreen(mode: ScannerMode.plate),
                      ),
                    );
                    if (plate != null && plate is String) {
                      widget.onTap(2);
                      widget.shellContext.read<ShellNavigationProvider>().setIndex(2, prefilledPlate: plate);
                    }
                  } else {
                    _showPermissionDeniedSnackBar();
                  }
                },
              ),
              const SizedBox(height: 16),
              
              _buildOptionCard(
                context: context,
                title: 'Check Out Vehicle',
                subtitle: 'Scan Entry Ticket (QR Code)',
                icon: LucideIcons.qrCode,
                color: AppTheme.primary,
                onTap: () async {
                  Navigator.pop(context);
                  final status = await Permission.camera.request();
                  if (status.isGranted) {
                    if (!mounted) return;
                    final sessionId = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScannerScreen(mode: ScannerMode.qr),
                      ),
                    );
                    if (sessionId != null && sessionId is String) {
                      _fetchAndConfirmCheckout(sessionId);
                    }
                  } else {
                    _showPermissionDeniedSnackBar();
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showPermissionDeniedSnackBar() {
    ScaffoldMessenger.of(widget.shellContext).showSnackBar(
      const SnackBar(content: Text('Camera permission is required to scan.')),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.06),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  LucideIcons.chevronRight,
                  color: isDark ? Colors.white24 : Colors.black26,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchAndConfirmCheckout(String sessionId) async {
    await CheckoutHelper.fetchAndConfirmCheckout(widget.shellContext, sessionId);
  }


  Widget _buildTicketRow(String label, String value, {bool isBold = false, bool highlight = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(widget.shellContext))),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold || highlight ? FontWeight.bold : FontWeight.normal,
              color: color ?? (highlight ? AppTheme.warning : AppTheme.textPrimary(widget.shellContext)),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for notched shape
class BottomBarPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final Color borderColor;

  BottomBarPainter({
    required this.color,
    required this.shadowColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    // Notch center and curves
    final cx = w / 2;
    const notchRadius = 38.0;
    const topMargin = 20.0; // The curve starts below the top limit to match normal bars

    final path = Path();
    
    // Start top-left
    path.moveTo(0, topMargin + 16);
    // Rounded top-left corner
    path.quadraticBezierTo(0, topMargin, 16, topMargin);
    
    // Line to start of notch
    path.lineTo(cx - notchRadius - 12, topMargin);
    
    // Notch curve (smooth bezier)
    path.cubicTo(
      cx - notchRadius,
      topMargin,
      cx - notchRadius + 6,
      topMargin + notchRadius * 0.95,
      cx,
      topMargin + notchRadius * 0.95,
    );
    path.cubicTo(
      cx + notchRadius - 6,
      topMargin + notchRadius * 0.95,
      cx + notchRadius,
      topMargin,
      cx + notchRadius + 12,
      topMargin,
    );

    // Line to top-right
    path.lineTo(w - 16, topMargin);
    // Rounded top-right corner
    path.quadraticBezierTo(w, topMargin, w, topMargin + 16);
    
    // Line to bottom-right, bottom-left and close
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // Draw Shadow
    canvas.drawShadow(path, shadowColor, 10.0, true);

    // Draw background fill
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Draw border stroke
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Clipper matching the notched painter for backdrop filter
class BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const notchRadius = 38.0;
    const topMargin = 20.0;

    final path = Path();
    path.moveTo(0, topMargin + 16);
    path.quadraticBezierTo(0, topMargin, 16, topMargin);
    path.lineTo(cx - notchRadius - 12, topMargin);
    path.cubicTo(
      cx - notchRadius,
      topMargin,
      cx - notchRadius + 6,
      topMargin + notchRadius * 0.95,
      cx,
      topMargin + notchRadius * 0.95,
    );
    path.cubicTo(
      cx + notchRadius - 6,
      topMargin + notchRadius * 0.95,
      cx + notchRadius,
      topMargin,
      cx + notchRadius + 12,
      topMargin,
    );
    path.lineTo(w - 16, topMargin);
    path.quadraticBezierTo(w, topMargin, w, topMargin + 16);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
