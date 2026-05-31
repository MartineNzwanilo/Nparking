import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'dart:typed_data';

class PrintingService {
  // ─── Silent Bluetooth ESC/POS print (auto-print, no dialog) ─────────────
  static Future<void> printTicket(Map<String, dynamic> session) async {
    try {
      // Check if Bluetooth is on and a printer is already connected/paired
      final bool btEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      if (!btEnabled) {
        debugPrint('[PrintingService] Bluetooth is off — skipping auto-print');
        return;
      }

      // Look for a paired printer that is already bonded
      final List<BluetoothInfo> devices =
          await PrintBluetoothThermal.pairedBluetooths;
      if (devices.isEmpty) {
        debugPrint('[PrintingService] No paired Bluetooth printers found');
        return;
      }

      // Connect to the first paired printer
      final BluetoothInfo printer = devices.first;
      final bool connected =
          await PrintBluetoothThermal.connect(macPrinterAddress: printer.macAdress);
      if (!connected) {
        debugPrint('[PrintingService] Could not connect to ${printer.name}');
        return;
      }

      // Build ESC/POS receipt bytes
      final List<int> bytes = await _buildEscPosBytes(session);
      await PrintBluetoothThermal.writeBytes(bytes);
      debugPrint('[PrintingService] Ticket printed on ${printer.name}');
    } catch (e) {
      debugPrint('[PrintingService] Auto-print failed: $e');
    }
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
    final generator = Generator(PaperSize.mm80, profile);
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
    final String driverName = session['driverName'] ?? '';
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

    // Ticket details
    bytes += generator.row([
      PosColumn(text: 'Ticket', width: 5),
      PosColumn(
          text: ticketId.length > 8
              ? ticketId.substring(0, 8).toUpperCase()
              : ticketId,
          width: 7,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Plate No.', width: 5),
      PosColumn(
          text: plate,
          width: 7,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Category', width: 5),
      PosColumn(
          text: category,
          width: 7,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Date', width: 5),
      PosColumn(
          text: dateStr,
          width: 7,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (driverName.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Driver', width: 5),
        PosColumn(
            text: driverName,
            width: 7,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    if (driverPhone.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Phone', width: 5),
        PosColumn(
            text: driverPhone,
            width: 7,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    if (watchman.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Watchman', width: 5),
        PosColumn(
            text: watchman,
            width: 7,
            styles: const PosStyles(align: PosAlign.right)),
      ]);
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
    bytes += generator.row([
      PosColumn(
          text: 'FEE',
          width: 5,
          styles: const PosStyles(bold: true)),
      PosColumn(
          text: 'TZS ${amount.toStringAsFixed(0)}',
          width: 7,
          styles: const PosStyles(
              bold: true,
              align: PosAlign.right,
              height: PosTextSize.size2,
              width: PosTextSize.size2)),
    ]);
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
    final String driverName = session['driverName'] ?? 'N/A';
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
}
