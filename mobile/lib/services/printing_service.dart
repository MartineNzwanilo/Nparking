import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database_helper.dart';

class PrintingService {
  static Future<bool> _isPrinterReachable(String ip) async {
    String host = ip;
    int port = 9100;
    if (ip.contains(':')) {
      final parts = ip.split(':');
      host = parts[0];
      if (parts.length > 1) {
        port = int.tryParse(parts[1]) ?? 9100;
      }
    }

    // Determine if it is a local LAN address
    bool isLocal = false;
    if (host.startsWith('192.168.') || host.startsWith('10.')) {
      isLocal = true;
    } else if (host.startsWith('172.')) {
      final parts = host.split('.');
      if (parts.length > 1) {
        final second = int.tryParse(parts[1]);
        if (second != null && second >= 16 && second <= 31) {
          isLocal = true;
        }
      }
    } else if (host.endsWith('.local') || host == 'localhost' || host == '127.0.0.1') {
      isLocal = true;
    }

    // Local LAN pings fail quickly, while DNS lookups and WAN handshakes on cell data need more time (e.g. 3.5s)
    final timeout = isLocal ? const Duration(seconds: 1) : const Duration(milliseconds: 3500);

    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Unified ESC/POS Printer Sender ─────────────────────────────────────────
  static Future<void> _sendBytesToPrinters(BuildContext? context, List<int> bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to load new multiple network printers list inherited from backend
      final String? printersJson = prefs.getString('auth_offline_site_printers');
      List<dynamic> networkPrinters = [];
      if (printersJson != null) {
        networkPrinters = jsonDecode(printersJson);
      } else {
        // Fallback to legacy single IP
        final String? networkIp = prefs.getString('network_printer_ip');
        if (networkIp != null && networkIp.isNotEmpty) {
          networkPrinters.add({
            'ip': networkIp,
            'name': 'Default Printer',
            'isDefault': true,
            'printSimultaneously': true,
          });
        }
      }

      bool printedOnNetwork = false;

      if (networkPrinters.isNotEmpty) {
        List<dynamic> targetPrinters = [];
        
        if (context != null) {
          List<dynamic>? selectedList = await showDialog<List<dynamic>>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              // Only the default printer should be checked by default
              final defaultPrinter = networkPrinters.firstWhere((p) => p['isDefault'] == true, orElse: () => networkPrinters.first);
              List<dynamic> selectedPrinters = [defaultPrinter];

              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Select Printers'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Tick the printers you want to print to:',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ...networkPrinters.map((p) {
                            final isSelected = selectedPrinters.any((item) => item['ip'] == p['ip']);
                            return CheckboxListTile(
                              title: Text(p['name'] ?? p['ip']),
                              subtitle: Text(p['ip']),
                              value: isSelected,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (bool? checked) {
                                setState(() {
                                  if (checked == true) {
                                    if (!selectedPrinters.any((item) => item['ip'] == p['ip'])) {
                                      selectedPrinters.add(p);
                                    }
                                  } else {
                                    selectedPrinters.removeWhere((item) => item['ip'] == p['ip']);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null), // Cancel printing completely
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, selectedPrinters),
                        child: Text(selectedPrinters.isEmpty ? 'Don\'t Print' : 'Print'),
                      ),
                    ],
                  );
                }
              );
            }
          );

          if (selectedList == null || selectedList.isEmpty) {
            return; // Abort or skip printing
          }

          targetPrinters = selectedList;
        } else {
          // Silent automatic selection (background or non-context flows)
          final simultaneousPrinters = networkPrinters.where((p) => p['printSimultaneously'] == true).toList();
          if (simultaneousPrinters.isNotEmpty) {
            targetPrinters = simultaneousPrinters;
          } else {
            final defaultPrinter = networkPrinters.firstWhere((p) => p['isDefault'] == true, orElse: () => networkPrinters.first);
            targetPrinters = [defaultPrinter];
          }
        }

        // Fire off requests to all target printers concurrently
        List<Future<void>> printTasks = [];
        for (var printer in targetPrinters) {
          final ip = printer['ip'] as String;
          printTasks.add(() async {
            String host = ip;
            int port = 9100;
            if (ip.contains(':')) {
              final parts = ip.split(':');
              host = parts[0];
              if (parts.length > 1) {
                port = int.tryParse(parts[1]) ?? 9100;
              }
            }
            debugPrint('[PrintingService] Attempting to print via Network (TCP) to $host:$port');
            try {
              final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
              socket.add(bytes);
              await socket.flush();
              socket.destroy();
              debugPrint('[PrintingService] Ticket printed successfully on $host:$port');
              printedOnNetwork = true;
            } catch (e) {
              debugPrint('[PrintingService] Network print failed to $host:$port: $e, adding to print_queue');
              try {
                final db = await DatabaseHelper.instance.database;
                await db.insert('print_queue', {
                  'printerIp': ip,
                  'bytes': base64Encode(bytes),
                  'timestamp': DateTime.now().toIso8601String(),
                });
              } catch (dbErr) {
                debugPrint('[PrintingService] Failed to add print job to queue: $dbErr');
              }
            }
          }());
        }

        await Future.wait(printTasks);
      }

      if (printedOnNetwork) {
        return; // Success, skip Bluetooth
      }

      // 2. Fallback to Bluetooth
      final bool btEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!btEnabled) {
        debugPrint('[PrintingService] Bluetooth is off — skipping auto-print');
        return;
      }

      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      if (devices.isEmpty) {
        debugPrint('[PrintingService] No paired Bluetooth printers found');
        return;
      }

      final BluetoothInfo printer = devices.first;
      final bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: printer.macAdress);
      if (!connected) {
        debugPrint('[PrintingService] Could not connect to ${printer.name}');
        return;
      }

      await PrintBluetoothThermal.writeBytes(bytes);
      debugPrint('[PrintingService] Ticket printed on ${printer.name}');
    } catch (e) {
      debugPrint('[PrintingService] Auto-print failed: $e');
    }
  }

  // ─── Direct Print Triggers ──────────────────────────────────────────────────
  static Future<void> printTicket(BuildContext? context, Map<String, dynamic> session) async {
    try {
      final bytes = await _buildEscPosBytes(session);
      await _sendBytesToPrinters(context, bytes);
    } catch (e) {
      debugPrint('[PrintingService] printTicket failed: $e');
      rethrow;
    }
  }

  static Future<void> printLodgeAuthorization(BuildContext? context, Map<String, dynamic> session) async {
    try {
      final bytes = await _buildLodgeAuthBytes(session);
      await _sendBytesToPrinters(context, bytes);
    } catch (e) {
      debugPrint('[PrintingService] printLodgeAuthorization failed: $e');
      rethrow;
    }
  }

  static Future<void> printActivityReport(BuildContext? context, List<Map<String, dynamic>> activities) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.reset();

      // Header
      bytes += generator.text(
        'NGEWA PARKING SYSTEM',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
      );
      bytes += generator.text(
        'ACTIVITY REPORT',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'Printed: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr();
      bytes += generator.feed(1);

      // Total count
      bytes += generator.text('Total Records: ${activities.length}', styles: const PosStyles(bold: true));
      bytes += generator.feed(1);

      // Column Headers
      bytes += generator.row([
        PosColumn(text: 'Time', width: 3, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Plate', width: 4, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Action', width: 5, styles: const PosStyles(bold: true)),
      ]);
      bytes += generator.hr();

      // Activity Rows
      for (var act in activities) {
        final timeStr = act['timestamp'] != null 
            ? DateFormat('HH:mm').format(DateTime.tryParse(act['timestamp'].toString()) ?? DateTime.now()) 
            : '';
        final plate = act['title']?.toString() ?? '';
        final action = act['type']?.toString() ?? '';
        
        bytes += generator.row([
          PosColumn(text: timeStr, width: 3),
          PosColumn(text: plate, width: 4),
          PosColumn(text: action, width: 5),
        ]);
      }

      bytes += generator.hr();
      bytes += generator.feed(2);
      bytes += generator.cut();

      await _sendBytesToPrinters(context, bytes);
    } catch (e) {
      debugPrint('[PrintingService] Failed to print Activity Report: $e');
      throw Exception('Failed to print activity report');
    }
  }

  /// Strips non-ASCII / non-printable characters so ESC/POS printer doesn't reject the string.
  static String _toAscii(String input) {
    // Replace common Unicode punctuation with ASCII equivalents
    return input
        .replaceAll('\u2026', '...')  // ellipsis …
        .replaceAll('\u2014', '-')    // em dash —
        .replaceAll('\u2013', '-')    // en dash –
        .replaceAll('\u2018', "'")   // left single quote '
        .replaceAll('\u2019', "'")   // right single quote '
        .replaceAll('\u201C', '"')   // left double quote "
        .replaceAll('\u201D', '"')   // right double quote "
        .replaceAll('\u00e9', 'e')   // é
        .replaceAll('\u00e0', 'a')   // à
        .replaceAllMapped(
          RegExp(r'[^\x20-\x7E]'), // remove anything outside printable ASCII range
          (_) => '?',
        );
  }

  /// Prints any admin tabular report to the ESC/POS network printer.
  /// [title] – e.g. "Daily Revenue", [summary] – key/value summary map,
  /// [rows] – list of row maps from the backend report endpoint.
  static Future<void> printAdminReport(
    BuildContext context,
    String title,
    Map<String, dynamic>? summary,
    List<dynamic> rows,
  ) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.reset();

      // ── Header ────────────────────────────────────────────────────────────
      bytes += generator.text(
        _toAscii('NGEWA PARKING SYSTEM'),
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
      );
      bytes += generator.text(
        _toAscii(title.toUpperCase()),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        _toAscii('Printed: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}'),
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.hr();
      bytes += generator.feed(1);

      if (title.toUpperCase() == 'FINANCIALS') {
        bytes += _buildIncomeStatementBytes(generator, summary, rows);
      } else {
        // ── Summary Block ─────────────────────────────────────────────────────
        if (summary != null && summary.isNotEmpty) {
        bytes += generator.text('SUMMARY', styles: const PosStyles(bold: true));
        bytes += generator.feed(1);
        for (final entry in summary.entries) {
          final label = _toAscii(
            entry.key
                .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
                .trim()
                .toUpperCase(),
          );
          final value = _toAscii(entry.value?.toString() ?? '-');
          // Fixed-width: label 20 chars, value up to 12 chars
          final labelPad = label.length > 20 ? label.substring(0, 20) : label.padRight(20);
          final valuePad = value.length > 12 ? value.substring(value.length - 12) : value.padLeft(12);
          bytes += generator.text('$labelPad$valuePad');
        }
        bytes += generator.hr();
        bytes += generator.feed(1);
      }

      // ── Records ───────────────────────────────────────────────────────────
      bytes += generator.text('RECORDS: ${rows.length}', styles: const PosStyles(bold: true));
      bytes += generator.feed(1);

      if (rows.isNotEmpty) {
        final firstRow = rows[0] as Map<String, dynamic>;
        final headers = firstRow.keys.toList();

        // Print up to 3 columns on 58mm paper
        final visibleHeaders = headers.take(3).toList();
        final colWidth = (12 / visibleHeaders.length).floor();
        final maxChars = colWidth * 4; // ESC/POS column width in characters

        // Header row
        bytes += generator.row(
          visibleHeaders.map((h) {
            final label = _toAscii(
              h.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}').trim().toUpperCase(),
            );
            final abbr = label.length > maxChars ? label.substring(0, maxChars) : label;
            return PosColumn(text: abbr, width: colWidth, styles: const PosStyles(bold: true));
          }).toList(),
        );
        bytes += generator.hr(ch: '-');

        // Data rows (max 50 to avoid extremely long prints)
        for (final row in rows.take(50)) {
          final rowMap = row as Map<String, dynamic>;
          bytes += generator.row(
            visibleHeaders.map((h) {
              final raw = _toAscii(rowMap[h]?.toString() ?? '-');
              final cell = raw.length > maxChars ? '${raw.substring(0, maxChars - 3)}...' : raw;
              return PosColumn(text: cell, width: colWidth);
            }).toList(),
          );
        }

        if (rows.length > 50) {
          bytes += generator.feed(1);
          bytes += generator.text('... ${rows.length - 50} more records', styles: const PosStyles(align: PosAlign.center));
        }
      }

      }

      bytes += generator.hr();
      bytes += generator.text(
        'End of Report',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.feed(3);
      bytes += generator.cut();

      await _sendBytesToPrinters(context, bytes);
    } catch (e) {
      debugPrint('[PrintingService] Failed to print admin report: $e');
      throw Exception('Failed to print admin report: $e');
    }
  }

  static List<int> _buildIncomeStatementBytes(Generator generator, Map<String, dynamic>? summary, List<dynamic> rows) {
    List<int> bytes = [];
    final grossRevenue = (summary?['grossRevenue'] as num?)?.toDouble() ?? 0;
    final totalExpenses = (summary?['totalExpenses'] as num?)?.toDouble() ?? 0;
    final netProfit = (summary?['netProfit'] as num?)?.toDouble() ?? 0;

    final expenseRows = rows.where((r) => (r as Map)['type'] == 'EXPENSE').toList();
    final revenueRows = rows.where((r) => (r as Map)['type'] == 'REVENUE').toList();

    // -- REVENUE --
    bytes += generator.text('REVENUE', styles: const PosStyles(bold: true));
    bytes += generator.feed(1);
    for (var r in revenueRows) {
      final map = r as Map;
      final cat = _toAscii(map['category']?.toString() ?? 'Other');
      final amt = (map['amount'] as num?)?.toDouble() ?? 0;
      final amtStr = amt.toStringAsFixed(0);
      final labelPad = cat.length > 20 ? cat.substring(0, 20) : cat.padRight(20);
      final valuePad = amtStr.length > 12 ? amtStr.substring(amtStr.length - 12) : amtStr.padLeft(12);
      bytes += generator.text('$labelPad$valuePad');
    }
    bytes += generator.hr(ch: '-');
    final totalRevLabel = 'TOTAL REVENUE'.padRight(20);
    final totalRevVal = grossRevenue.toStringAsFixed(0).padLeft(12);
    bytes += generator.text('$totalRevLabel$totalRevVal', styles: const PosStyles(bold: true));
    bytes += generator.feed(1);

    // -- EXPENSES --
    bytes += generator.text('EXPENSES', styles: const PosStyles(bold: true));
    bytes += generator.feed(1);
    for (var r in expenseRows) {
      final map = r as Map;
      final cat = _toAscii(map['category']?.toString() ?? 'Other');
      final amt = (map['amount'] as num?)?.toDouble() ?? 0;
      final amtStr = amt.toStringAsFixed(0);
      final labelPad = cat.length > 20 ? cat.substring(0, 20) : cat.padRight(20);
      final valuePad = amtStr.length > 12 ? amtStr.substring(amtStr.length - 12) : amtStr.padLeft(12);
      bytes += generator.text('$labelPad$valuePad');
    }
    bytes += generator.hr(ch: '-');
    final totalExpLabel = 'TOTAL EXPENSES'.padRight(20);
    final totalExpVal = totalExpenses.toStringAsFixed(0).padLeft(12);
    bytes += generator.text('$totalExpLabel$totalExpVal', styles: const PosStyles(bold: true));
    bytes += generator.feed(1);

    // -- NET INCOME --
    bytes += generator.hr();
    final netIncomeLabel = 'NET PROFIT / LOSS'.padRight(20);
    final netIncomeVal = netProfit.toStringAsFixed(0).padLeft(12);
    bytes += generator.text('$netIncomeLabel$netIncomeVal', styles: const PosStyles(bold: true, width: PosTextSize.size1, height: PosTextSize.size2));
    
    return bytes;
  }



  // ─── Manual print — opens system dialog (called from ticket view) ────────
  static Future<void> showPrintDialog(
      BuildContext context, Map<String, dynamic> session) async {
    final doc = await _buildPdfDoc(session);
    final String plate =
        session['vehicle']?['plateNumber'] ?? 'ticket';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Parking_Ticket_$plate',
    );
  }

  // ─── ESC/POS bytes builder ────────────────────────────────────────────────
  static Future<List<int>> _buildEscPosBytes(
      Map<String, dynamic> session) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    final vehicle = session['vehicle'];
    final String plate =
        vehicle != null ? vehicle['plateNumber'] ?? '' : '';
    final String category =
        (vehicle != null && vehicle['category'] != null)
            ? vehicle['category']['name'] ?? ''
            : '';
    final String watchman =
        session['watchman'] != null ? session['watchman']['name'] ?? '' : '';
    final DateTime date =
        DateTime.tryParse(session['checkIn'] ?? '') ?? DateTime.now();
    final String dateStr =
        DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final num amount = session['amountDue'] ?? 0;
    final String ticketId = session['id'] ?? '';
    
    // Fallback to vehicle's ownerName if driverName is not provided in session
    String driverName = session['driverName'] ?? '';
    if (driverName.trim().isEmpty && vehicle != null && vehicle['ownerName'] != null) {
      driverName = vehicle['ownerName'];
    }
    
    final String driverPhone = session['driverPhone'] ?? '';
    final String propertiesLeft = session['propertiesLeft'] ?? '';

    bytes += generator.reset();

    // Header
    bytes += generator.text(
      'NGEWA PARKING SYSTEM',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );
    bytes += generator.text(
      'Smart Parking Entry Ticket',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    // Ticket details with improved monospace left-alignment
    bytes += generator.text('Ticket No: ${ticketId.length > 8 ? ticketId.substring(0, 8).toUpperCase() : ticketId}', styles: const PosStyles(bold: true));
    bytes += generator.text('Plate No:  $plate', styles: const PosStyles(bold: true));
    bytes += generator.text('Category:  $category');
    bytes += generator.text('Date:      $dateStr');
    
    if (driverName.trim().isNotEmpty) {
      bytes += generator.text('Driver:    $driverName');
    }
    if (driverPhone.trim().isNotEmpty) {
      bytes += generator.text('Phone:     $driverPhone');
    }
    if (watchman.trim().isNotEmpty) {
      bytes += generator.text('Watchman:  $watchman');
    }

    if (propertiesLeft.isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text(
        'Properties Left:',
        styles: const PosStyles(bold: true),
      );
      bytes += generator.text(propertiesLeft);
      bytes += generator.hr(ch: '-');
    }

    bytes += generator.hr();
    bytes += generator.text(
      'FEE: TZS ${amount.toStringAsFixed(0)}',
      styles: const PosStyles(
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.hr();

    // QR Code with session ID
    bytes += generator.qrcode(ticketId, size: QRSize.size4);
    bytes += generator.text(
      'Scan at Checkout',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Thank you for parking with us!',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  // ─── ESC/POS bytes builder for Lodge Auth ──────────────────────────────────
  static Future<List<int>> _buildLodgeAuthBytes(Map<String, dynamic> session) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    final vehicle = session['vehicle'];
    final String plate = vehicle != null ? vehicle['plateNumber'] ?? '' : '';
    final String category = (vehicle != null && vehicle['category'] != null)
        ? vehicle['category']['name'] ?? '' : '';
    final String watchman = session['watchman'] != null ? session['watchman']['name'] ?? '' : '';
    final String roomNo = session['lodgeRoomNumber'] ?? 'N/A';
    
    final DateTime checkInDate = DateTime.tryParse(session['checkIn'] ?? '') ?? DateTime.now();
    final String checkInStr = DateFormat('dd MMM yyyy, HH:mm').format(checkInDate);
    final String authTimeStr = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    bytes += generator.reset();

    // Header
    bytes += generator.text(
      'NGEWA PARKING SYSTEM',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
    );
    bytes += generator.text(
      'LODGE PARKING AUTH',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr();

    // Ticket details
    bytes += generator.text('Plate No:  $plate', styles: const PosStyles(bold: true));
    bytes += generator.text('Category:  $category');
    bytes += generator.text('Watchman:  $watchman');
    bytes += generator.text('Room No:   $roomNo', styles: const PosStyles(bold: true));
    bytes += generator.text('Check-in:  $checkInStr');
    bytes += generator.text('Auth Time: $authTimeStr');
    
    bytes += generator.hr(ch: '-');
    
    // Fee Status
    bytes += generator.text(
      'PARKING FEE WAIVED (TZS 0)',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    
    bytes += generator.hr();
    bytes += generator.text(
      'Thank you for your stay!',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(3);
    bytes += generator.cut();

    return bytes;
  }

  // ─── PDF doc builder (for manual dialog print) ───────────────────────────
  static Future<pw.Document> _buildPdfDoc(
      Map<String, dynamic> session) async {
    final vehicle = session['vehicle'];
    final String plate =
        vehicle != null ? vehicle['plateNumber'] ?? '' : '';
    final String category =
        (vehicle != null && vehicle['category'] != null)
            ? vehicle['category']['name'] ?? ''
            : '';
    final String watchman =
        session['watchman'] != null ? session['watchman']['name'] ?? '' : '';
    final DateTime date =
        DateTime.tryParse(session['checkIn'] ?? '') ?? DateTime.now();
    final String dateStr =
        DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final num amount = session['amountDue'] ?? 0;
    final String ticketId = session['id'] ?? '';
    
    // Fallback to vehicle's ownerName if driverName is not provided in session
    String driverName = session['driverName'] ?? '';
    if (driverName.trim().isEmpty || driverName == 'N/A') {
      if (vehicle != null && vehicle['ownerName'] != null && vehicle['ownerName'].toString().trim().isNotEmpty) {
        driverName = vehicle['ownerName'];
      } else {
        driverName = 'N/A';
      }
    }
    
    final String driverPhone = session['driverPhone'] ?? 'N/A';
    final String driverCompany = session['driverCompany'] ?? 'N/A';
    final String? propertiesLeft = session['propertiesLeft'];

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('NGEWA PARKING SYSTEM',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Smart Parking Entry Ticket',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.BarcodeWidget(
                color: PdfColor.fromHex('#000000'),
                barcode: pw.Barcode.qrCode(),
                data: ticketId,
                width: 100,
                height: 100,
              ),
              pw.SizedBox(height: 5),
              pw.Text('Scan at Checkout',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 15),
              _buildRow('Ticket ID',
                  ticketId.length > 8
                      ? ticketId.substring(0, 8).toUpperCase()
                      : ticketId,
                  isBold: true),
              _buildRow('Plate No.', plate, isBold: true),
              _buildRow('Category', category),
              _buildRow('Date', dateStr),
              _buildRow('Driver', driverName),
              _buildRow('Phone', driverPhone),
              _buildRow('Company', driverCompany),
              if (watchman.isNotEmpty) _buildRow('Watchman', watchman),
              if (propertiesLeft != null &&
                  propertiesLeft.trim().isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.Text('Properties Left in Vehicle:',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(propertiesLeft.trim(),
                    style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 5),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),
              ],
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 5),
              _buildRow('Fee Paid', 'TZS ${amount.toStringAsFixed(0)}',
                  isBold: true),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Thank you for parking with us!',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );
    return doc;
  }

  static pw.Widget _buildRow(String label, String value,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  // ─── PDF doc builder for Expense Report ──────────────────────────────────
  static Future<pw.Document> buildExpenseReportPdf(
      List<dynamic> expenses, String dateRange, double total) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('NGEWA PARKING SYSTEM',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Expense Report',
                        style: pw.TextStyle(
                            fontSize: 18, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Generated On:',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now()),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Period:',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(dateRange,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Summary Cards
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Expenses',
                          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                      pw.Text('TZS ${NumberFormat.decimalPattern().format(total)}',
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total Transactions',
                          style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                      pw.Text('${expenses.length}',
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Table Header
            pw.Text('Transaction Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2), // Date
                1: pw.FlexColumnWidth(2), // Category
                2: pw.FlexColumnWidth(3), // Description/Paid To
                3: pw.FlexColumnWidth(2), // Amount
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Amount (TZS)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10), textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                // Data Rows
                ...expenses.map((exp) {
                  final catName = exp['category']?['name'] ?? 'Unknown';
                  final amount = (exp['amount'] as num?)?.toDouble() ?? 0;
                  final date = DateTime.tryParse(exp['date'] ?? '') ?? DateTime.now();
                  final desc = exp['description'] ?? '';
                  final paidTo = exp['paidToUser']?['name'];

                  String details = desc;
                  if (paidTo != null) {
                    details += details.isNotEmpty ? '\nPaid to: $paidTo' : 'Paid to: $paidTo';
                  }
                  if (details.isEmpty) details = '-';

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(catName, style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(details, style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(NumberFormat.decimalPattern().format(amount), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red700), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('End of Report', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            ),
          ];
        },
      ),
    );

    return doc;
  }

  static bool _isProcessingPending = false;

  static Future<void> processPendingPrintJobs() async {
    if (_isProcessingPending) return;
    _isProcessingPending = true;
    try {
      final db = await DatabaseHelper.instance.database;
      final queue = await db.query('print_queue', orderBy: 'timestamp ASC');
      
      if (queue.isNotEmpty) {
        for (var item in queue) {
          final id = item['id'] as int;
          final ip = item['printerIp'] as String;
          final base64Bytes = item['bytes'] as String;
          final bytes = base64Decode(base64Bytes);
 
          String host = ip;
          int port = 9100;
          if (ip.contains(':')) {
            final parts = ip.split(':');
            host = parts[0];
            if (parts.length > 1) {
              port = int.tryParse(parts[1]) ?? 9100;
            }
          }
 
          try {
            debugPrint('[PrintingService] Attempting to print pending job $id to $host:$port');
            final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
            socket.add(bytes);
            await socket.flush();
            socket.destroy();
            
            // If successful, delete from queue
            await db.delete('print_queue', where: 'id = ?', whereArgs: [id]);
            debugPrint('[PrintingService] Successfully printed and cleared pending job $id');
          } catch (e) {
            debugPrint('[PrintingService] Pending job $id to $host:$port still failing: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[PrintingService] Error processing pending print jobs: $e');
    } finally {
      _isProcessingPending = false;
    }
  }
}
