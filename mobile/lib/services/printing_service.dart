import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class PrintingService {
  static Future<void> printTicket(Map<String, dynamic> session) async {
    final vehicle = session['vehicle'];
    final plate = vehicle != null ? vehicle['plateNumber'] ?? '' : '';
    final category = (vehicle != null && vehicle['category'] != null) ? vehicle['category']['name'] ?? '' : '';
    final watchman = session['watchman'] != null ? session['watchman']['name'] ?? '' : '';
    final date = DateTime.tryParse(session['checkIn'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final amount = session['amountDue'] ?? 0.0;
    final ticketId = session['id'] ?? '';
    
    final driverName = session['driverName'] ?? 'N/A';
    final driverPhone = session['driverPhone'] ?? 'N/A';
    final driverCompany = session['driverCompany'] ?? 'N/A';

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // 80mm thermal receipt format
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'NGEWA PARKING SYSTEM',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Smart Parking Entry Ticket', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              pw.BarcodeWidget(
                color: PdfColor.fromHex("#000000"),
                barcode: pw.Barcode.qrCode(),
                data: ticketId,
                width: 100,
                height: 100,
              ),
              pw.SizedBox(height: 5),
              pw.Text('Scan at Checkout', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 15),

              _buildRow('Ticket ID', ticketId.length > 8 ? ticketId.substring(0, 8).toUpperCase() : ticketId, isBold: true),
              _buildRow('Plate No.', plate, isBold: true),
              _buildRow('Category', category),
              _buildRow('Date', dateStr),
              _buildRow('Driver', driverName),
              _buildRow('Phone', driverPhone),
              _buildRow('Company', driverCompany),
              
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 5),
              _buildRow('Fee Paid', 'TZS ${amount.toStringAsFixed(0)}', isBold: true),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              pw.Text('Thank you for parking with us!', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 5),
              pw.Text('Powered by Antigravity', style: const pw.TextStyle(fontSize: 8)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Parking_Ticket_$plate',
    );
  }

  static pw.Widget _buildRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            value, 
            style: pw.TextStyle(
              fontSize: 10, 
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal
            ),
          ),
        ],
      ),
    );
  }
}
