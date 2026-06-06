import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/vehicle_provider.dart';
import 'global_popup.dart';

class CheckoutHelper {
  static Future<void> fetchAndConfirmCheckout(BuildContext context, String sessionId) async {
    final provider = context.read<VehicleProvider>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      final session = await provider.fetchSessionDetails(sessionId);
      Navigator.pop(context);

      if (!context.mounted) return;
      
      if (session['status'] == 'COMPLETED' || session['status'] == 'CHECKED_OUT') {
        GlobalPopup.showError(context, 'This vehicle has already been checked out.');
        return;
      }
      
      final checkInDate = DateTime.tryParse(session['checkIn'] ?? '') ?? DateTime.now();
      if (hasOverstayed(checkInDate, provider.overstayTimeLimit)) {
         _showOverstayResolutionDialog(context, session, provider.overstayFineAmount);
      } else {
         _showCheckoutConfirmationDialog(context, session);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        String errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('404') || errorMsg.contains('not found')) {
           GlobalPopup.showError(context, 'Ticket not found. This vehicle is either not in the system or has already been checked out.');
        } else if (errorMsg.contains('400') || errorMsg.contains('already')) {
           GlobalPopup.showError(context, 'This vehicle has already been checked out.');
        } else {
           GlobalPopup.showError(context, 'Session lookup failed. This ticket might be invalid or you have no internet connection.');
        }
      }
    }
  }

  static bool hasOverstayed(DateTime checkIn, String limitTimeStr) {
    try {
      final parts = limitTimeStr.split(':');
      final limitHour = int.parse(parts[0]);
      final limitMinute = int.parse(parts[1]);
      
      DateTime deadline = DateTime(checkIn.year, checkIn.month, checkIn.day, limitHour, limitMinute);
      
      if (checkIn.isAfter(deadline) || checkIn.isAtSameMomentAs(deadline)) {
        deadline = deadline.add(const Duration(days: 1));
      }
      
      return DateTime.now().isAfter(deadline);
    } catch (e) {
      return false;
    }
  }

  static void _showOverstayResolutionDialog(BuildContext context, Map<String, dynamic> session, double fineAmount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vehicle = session['vehicle'] ?? {};
    final plate = vehicle['plateNumber'] ?? 'Unknown';
    final sessionId = session['id'];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Overstay Resolution',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.error.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(color: AppTheme.error.withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'OVERSTAY DETECTED',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.error, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vehicle $plate has exceeded the parking time limit.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(ctx)),
                  ),
                  const SizedBox(height: 24),
                  
                  // Option A
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _processCheckout(context, sessionId, plate, extraFine: fineAmount);
                    },
                    child: Column(
                      children: [
                        const Text('Vehicle is leaving NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('(Applies TZS ${fineAmount.toStringAsFixed(0)} Fine)', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Option B
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showManualDepartureTimeDialog(context, sessionId, plate, session['checkIn'] ?? '');
                    },
                    child: const Column(
                      children: [
                        Text('Vehicle left earlier (I forgot to scan)', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        Text('(Waive fine & Log Anomaly)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel Checkout', style: TextStyle(color: Colors.grey)),
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  static void _showManualDepartureTimeDialog(BuildContext context, String sessionId, String plate, String checkInIso) async {
     TimeOfDay? selectedTime = await showTimePicker(
       context: context,
       initialTime: TimeOfDay.now(),
       helpText: 'Select actual departure time',
     );

     if (selectedTime != null && context.mounted) {
       final now = DateTime.now();
       final departureDateTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
       
       // Verify it's after checkIn
       final checkInTime = DateTime.tryParse(checkInIso) ?? DateTime.now().subtract(const Duration(hours: 1));
       if (departureDateTime.isBefore(checkInTime)) {
          GlobalPopup.showError(context, 'Departure time cannot be before Check-In time.');
          return;
       }

       _processCheckout(
         context,
         sessionId, 
         plate, 
         actualDepartureTime: departureDateTime.toIso8601String(), 
         watchmanForgot: true
       );
     }
  }

  static void _processCheckout(BuildContext context, String sessionId, String plate, {double? extraFine, String? actualDepartureTime, bool watchmanForgot = false}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );

    try {
      await context.read<VehicleProvider>().checkOutVehicle(
        sessionId,
        fineAmount: extraFine,
        actualDepartureTime: actualDepartureTime,
        watchmanForgot: watchmanForgot,
      );
      Navigator.pop(context);
      
      GlobalPopup.showSuccess(
        context,
        watchmanForgot 
           ? 'Vehicle $plate checkout logged as a Watchman Anomaly.'
           : 'Vehicle $plate checked out successfully' + (extraFine != null ? ' with Fine.' : '.'),
        title: 'Checkout Success',
      );
    } catch (_) {
      Navigator.pop(context);
      GlobalPopup.showError(context, 'Failed to complete checkout. Please try again.');
    }
  }

  static void _showCheckoutConfirmationDialog(BuildContext context, Map<String, dynamic> session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vehicle = session['vehicle'] ?? {};
    final plate = vehicle['plateNumber'] ?? 'Unknown';
    final category = (vehicle['category'] != null) ? vehicle['category']['name'] : 'Unknown';
    final checkInDate = DateTime.tryParse(session['checkIn'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(checkInDate);
    final amount = (session['amountDue'] as num?)?.toDouble() ?? 0.0;
    final sessionId = session['id'];
    
    String driverName = session['driverName'] ?? '';
    if (driverName.trim().isEmpty || driverName == 'N/A') {
      driverName = vehicle['ownerName']?.toString().trim() ?? 'N/A';
      if (driverName.isEmpty) driverName = 'N/A';
    }

    String driverPhone = session['driverPhone'] ?? '';
    if (driverPhone.trim().isEmpty || driverPhone == 'N/A') {
      driverPhone = vehicle['phone']?.toString().trim() ?? 'N/A';
      if (driverPhone.isEmpty) driverPhone = 'N/A';
    }

    String driverCompany = session['driverCompany'] ?? '';
    if (driverCompany.trim().isEmpty || driverCompany == 'N/A') {
      driverCompany = vehicle['company']?.toString().trim() ?? 'N/A';
      if (driverCompany.isEmpty) driverCompany = 'N/A';
    }

    final diffMs = DateTime.now().difference(checkInDate).inMilliseconds;
    final diffHrs = diffMs ~/ 3600000;
    final diffMins = (diffMs % 3600000) ~/ 60000;
    final durationStr = '${diffHrs}h ${diffMins}m';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Checkout',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.88,
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.logOut, color: AppTheme.warning, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CONFIRM CHECKOUT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      plate,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildTicketRow(ctx, 'Vehicle Category', category),
                  _buildTicketRow(ctx, 'Entry Time', dateStr),
                  _buildTicketRow(ctx, 'Stay Duration', durationStr, highlight: true),
                  _buildTicketRow(ctx, 'Driver Name', driverName),
                  _buildTicketRow(ctx, 'Driver Phone', driverPhone),
                  _buildTicketRow(ctx, 'Driver Company', driverCompany),
                  _buildTicketRow(ctx, 'Amount Collected', 'TZS ${amount.toStringAsFixed(0)}', isBold: true, color: AppTheme.success),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                            );

                            try {
                              await context.read<VehicleProvider>().checkOutVehicle(sessionId);
                              Navigator.pop(context);
                              
                              GlobalPopup.showSuccess(
                                context,
                                'Vehicle $plate checked out successfully.',
                                title: 'Checkout Success',
                              );
                            } catch (_) {
                              Navigator.pop(context);
                              GlobalPopup.showError(context, 'Failed to complete checkout. Please try again.');
                            }
                          },
                          child: const Text('Check Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  static Widget _buildTicketRow(BuildContext context, String label, String value, {bool isBold = false, Color? color, bool highlight = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
          Container(
            padding: highlight ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2) : EdgeInsets.zero,
            decoration: highlight 
                ? BoxDecoration(color: AppTheme.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(6))
                : null,
            child: Text(
              value,
              style: TextStyle(
                color: color ?? AppTheme.textPrimary(context),
                fontWeight: isBold || highlight ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
