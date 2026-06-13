import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'api_service.dart';
import 'theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isRinging = false;
  BuildContext? _dialogContext;

  void initialize() {
    if (_socket != null) return;
    
    final baseUrl = ApiService.baseUrl.replaceFirst('/api', '');

    _socket = IO.io(
      '$baseUrl/notifications',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('Connected to Notification Gateway');
    });

    _socket!.on('lodge_request', (data) {
      debugPrint('Received lodge_request: $data');
      _handleIncomingAlert('New Free Parking Request', 'Vehicle: ${data['plateNumber']}\nFrom: ${data['watchmanName']}', data);
    });

    _socket!.on('lodge_response', (data) {
      debugPrint('Received lodge_response: $data');
      _handleIncomingAlert('Lodge Request ${data['status']}', 'Vehicle: ${data['plateNumber']}\nStatus: ${data['status']}', data);
    });

    _socket!.onDisconnect((_) => debugPrint('Disconnected from Notification Gateway'));

    _socket!.connect();
  }

  void _handleIncomingAlert(String title, String body, Map<String, dynamic> data) {
    if (navigatorKey.currentContext == null) return;
    
    // Check if user is logged in
    final auth = Provider.of<AuthProvider>(navigatorKey.currentContext!, listen: false);
    if (!auth.isAuthenticated || auth.user == null) return;

    final userRole = auth.user!['role'];
    final userSiteId = auth.user!['siteId'];
    final alertSiteId = data['siteId'];

    // If alert has a siteId, ignore it if it's not the user's site AND user is not an ADMIN
    if (alertSiteId != null && userSiteId != null && userSiteId != alertSiteId && userRole != 'ADMIN') {
      return;
    }

    final isRequest = data.containsKey('watchmanName');
    final isResponse = data.containsKey('status');

    if (isResponse && userRole == 'LODGEMAN') return;
    if (isRequest && userRole == 'WATCHMAN') return;

    _startRinging(title, body);
  }

  void _startRinging(String title, String body) {
    if (_isRinging) return;
    _isRinging = true;

    // Start playing the default ringtone loop
    FlutterRingtonePlayer().playRingtone(looping: true, volume: 1.0);

    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (ctx) {
        _dialogContext = ctx;
        return _buildIncomingAlert(title, body);
      },
    ).then((_) {
      _stopRinging();
    });
  }

  void _stopRinging() {
    _isRinging = false;
    FlutterRingtonePlayer().stop();
    _dialogContext = null;
  }

  void dismissAlert() {
    if (_dialogContext != null) {
      Navigator.of(_dialogContext!).pop();
    }
  }

  Widget _buildIncomingAlert(String title, String body) {
    final context = navigatorKey.currentContext!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 10,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.bellRing, size: 64, color: AppTheme.primary),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  dismissAlert();
                },
                icon: const Icon(LucideIcons.check),
                label: const Text('Acknowledge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
