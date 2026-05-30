import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/parking_i18n.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/shell_navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/vehicle_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, VehicleProvider, ActivityProvider>(
      builder: (context, auth, vehiclesProvider, activityProvider, child) {
        final vehicles = _toVehicleMaps(vehiclesProvider.vehicles);
        final activities =
            activityProvider.activities.cast<Map<String, dynamic>>();
        final insideVehicles = vehicles.where(_isInside).toList();
        final blacklistedVehicles =
            vehicles.where((v) => v['isBlacklisted'] == true).toList();
        final registeredCount = vehicles.length;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final greetingName = auth.name?.trim().isNotEmpty == true
            ? auth.name!.split(' ').first
            : context.t.tr('gateOperator');

        return Scaffold(
          backgroundColor:
              isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // ── Header ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),
                            Text(
                              greetingName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: isDark
                                    ? AppTheme.textPrimaryDark
                                    : AppTheme.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _IconBtn(
                        icon: LucideIcons.moon,
                        isDark: isDark,
                        onTap: () =>
                            context.read<ThemeProvider>().toggleTheme(),
                      ),
                      const SizedBox(width: 8),
                      _IconBtn(
                        icon: LucideIcons.languages,
                        isDark: isDark,
                        onTap: () => _showLanguageSheet(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Blacklist alert — ONLY when there's an actual alert ──
                  if (blacklistedVehicles.isNotEmpty)
                    _BlacklistBanner(vehicle: blacklistedVehicles.first),

                  if (blacklistedVehicles.isNotEmpty) const SizedBox(height: 16),

                  // ── Hero: vehicles inside right now ──────────────
                  _HeroCard(
                    insideCount: insideVehicles.length,
                    registeredCount: registeredCount,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 20),

                  // ── PRIMARY ACTION: Check In ──────────────────────
                  _PrimaryCheckInButton(isDark: isDark),

                  const SizedBox(height: 14),

                  // ── Secondary shortcuts ───────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryBtn(
                          icon: LucideIcons.car,
                          label: context.t.tr('vehicles'),
                          isDark: isDark,
                          onTap: () => context
                              .read<ShellNavigationProvider>()
                              .setIndex(1, maxIndex: 4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SecondaryBtn(
                          icon: LucideIcons.activity,
                          label: context.t.tr('activity'),
                          isDark: isDark,
                          onTap: () => context
                              .read<ShellNavigationProvider>()
                              .setIndex(3, maxIndex: 4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Last 3 activity entries (no header, no "view all") ──
                  if (activities.isNotEmpty) ...[
                    Text(
                      context.t.tr('recentActivity').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: math.min(activities.length, 3),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final activity =
                              activities.take(3).toList()[i];
                          return _ActivityRow(
                            activity: activity,
                            isDark: isDark,
                            onTap: () => context
                                .read<ShellNavigationProvider>()
                                .setIndex(3, maxIndex: 4),
                          );
                        },
                      ),
                    ),
                  ] else
                    const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  static List<Map<String, dynamic>> _toVehicleMaps(List<dynamic> vehicles) {
    return vehicles
        .whereType<Map>()
        .map((v) => v.cast<String, dynamic>())
        .toList();
  }

  static bool _isInside(Map<String, dynamic> vehicle) {
    final sessions = vehicle['sessions'];
    return sessions is List &&
        sessions.isNotEmpty &&
        sessions.first is Map &&
        sessions.first['status'] == 'INSIDE';
  }

  void _showLanguageSheet(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final current = localeProvider.locale?.languageCode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border:
              Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.t.tr('language'),
                  style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _LangOption(
                label: context.t.tr('systemDefault'),
                selected: current == null,
                onTap: () async {
                  await localeProvider.clearLocale();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              _LangOption(
                label: context.t.tr('english'),
                selected: current == 'en',
                onTap: () async {
                  await localeProvider.setLocale(const Locale('en'));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              _LangOption(
                label: context.t.tr('kiswahili'),
                selected: current == 'sw',
                onTap: () async {
                  await localeProvider.setLocale(const Locale('sw'));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BLACKLIST ALERT — only shown when alert exists
// ═══════════════════════════════════════════════════════════════════════════

class _BlacklistBanner extends StatefulWidget {
  const _BlacklistBanner({required this.vehicle});
  final Map<String, dynamic> vehicle;

  @override
  State<_BlacklistBanner> createState() => _BlacklistBannerState();
}

class _BlacklistBannerState extends State<_BlacklistBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plate =
        widget.vehicle['plateNumber']?.toString() ?? '—';
    final category =
        widget.vehicle['category']?['name']?.toString() ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: _pulse,
            child: const Icon(LucideIcons.shieldAlert,
                color: AppTheme.error, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠ BLACKLISTED: $plate',
                  style: const TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  category,
                  style: TextStyle(
                    color: AppTheme.error.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO CARD — vehicles inside count
// ═══════════════════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.insideCount,
    required this.registeredCount,
    required this.isDark,
  });

  final int insideCount;
  final int registeredCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ratio = registeredCount == 0
        ? 0.0
        : (insideCount / registeredCount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2E), Color(0xFF0A1628)],
        ),
      ),
      child: Row(
        children: [
          // Arc dial
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _ArcPainter(progress: ratio),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$insideCount',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Text(
                      context.t.tr('inside'),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.tr('parkingStatus'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                _DarkStat(
                  label: context.t.tr('registered'),
                  value: '$registeredCount',
                  color: AppTheme.success,
                ),
                const SizedBox(height: 10),
                // Occupancy bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Occupancy',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 4,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primary),
                      ),
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
}

class _DarkStat extends StatelessWidget {
  const _DarkStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Arc Painter ──────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const sw = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - sw;
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * progress,
        false,
        Paint()
          ..color = AppTheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════════
// PRIMARY CHECK-IN BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _PrimaryCheckInButton extends StatelessWidget {
  const _PrimaryCheckInButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () => context
            .read<ShellNavigationProvider>()
            .setIndex(2, maxIndex: 4),
        icon: const Icon(LucideIcons.scanLine, size: 22),
        label: Text(
          context.t.tr('checkIn'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECONDARY BUTTONS
// ═══════════════════════════════════════════════════════════════════════════

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIVITY ROW — minimal 3-line log
// ═══════════════════════════════════════════════════════════════════════════

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.isDark,
    required this.onTap,
  });

  final Map<String, dynamic> activity;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIn = activity['type'] == 'Check-In';
    final color = isIn ? AppTheme.primary : AppTheme.success;
    final time =
        _rel(context, activity['timestamp']?.toString() ?? '');

    return Material(
      color: isDark ? AppTheme.cardBgDark : AppTheme.cardBgLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                    isIn ? LucideIcons.logIn : LucideIcons.logOut,
                    color: color,
                    size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activity['title']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.textPrimaryDark
                        : AppTheme.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isIn ? 'IN' : 'OUT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rel(BuildContext context, String ts) {
    try {
      final d = DateTime.parse(ts);
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 1) return context.t.tr('justNow');
      if (diff.inHours < 1) {
        return context.t.tr('minutesAgo', {'minutes': '${diff.inMinutes}'});
      }
      if (diff.inDays < 1) {
        return context.t.tr('hoursAgo', {'hours': '${diff.inHours}'});
      }
      return context.t.tr('daysAgo', {'days': '${diff.inDays}'});
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.black.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18,
              color: isDark
                  ? AppTheme.textPrimaryDark
                  : AppTheme.textPrimaryLight),
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  const _LangOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style:
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ),
                Icon(
                  selected
                      ? LucideIcons.checkCircle2
                      : LucideIcons.circle,
                  color: selected ? AppTheme.primary : Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
