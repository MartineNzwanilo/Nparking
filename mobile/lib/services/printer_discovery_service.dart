import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

class PrinterDiscoveryService {
  static const int _printerPort = 9100;
  static const Duration _timeout = Duration(milliseconds: 1500);

  /// Discovers network ESC/POS printers on the current Wi-Fi subnet.
  static Future<List<String>> discoverPrinters() async {
    List<String> discoveredIps = [];
    String? wifiIP;
    
    try {
      final info = NetworkInfo();
      wifiIP = await info.getWifiIP();
    } catch (e) {
      debugPrint('[PrinterDiscovery] Error getting Wi-Fi IP: $e');
    }
    
    if (wifiIP == null || wifiIP.isEmpty) {
      debugPrint('[PrinterDiscovery] No Wi-Fi IP found. Are you connected to a network?');
      return discoveredIps;
    }

    final subnet = wifiIP.substring(0, wifiIP.lastIndexOf('.'));
    debugPrint('[PrinterDiscovery] Scanning subnet: $subnet.x on port $_printerPort');

    // Sweep in batches to avoid socket exhaustion
    const int batchSize = 32;
    for (int i = 1; i < 255; i += batchSize) {
      List<Future<void>> sweepTasks = [];
      for (int j = i; j < i + batchSize && j < 255; j++) {
        if ('$subnet.$j' == wifiIP) continue; // Skip own IP
        final host = '$subnet.$j';
        sweepTasks.add(_pingPrinter(host).then((isOpen) {
          if (isOpen) {
            debugPrint('[PrinterDiscovery] Found printer at $host');
            discoveredIps.add(host);
          }
        }));
      }
      await Future.wait(sweepTasks);
    }

    return discoveredIps;
  }

  /// Attempts to establish a TCP connection to the specified host and port.
  static Future<bool> _pingPrinter(String ip) async {
    try {
      final socket = await Socket.connect(ip, _printerPort, timeout: _timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}

