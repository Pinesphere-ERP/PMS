import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class InvoiceService {
  static Future<void> generateAndDownloadInvoice({
    required String guestName,
    required String roomNumber,
    required double totalAmount,
    required double paidAmount,
    required List<dynamic> payments,
  }) async {
    final pdf = pw.Document();
    
    // Add page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PineStay Resort', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 20, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 20),
              // Guest Info
              pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Guest Name: $guestName'),
              pw.Text('Room Number: $roomNumber'),
              pw.SizedBox(height: 20),
              // Payment Items
              pw.Text('Payment History', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Mode', 'Transaction ID', 'Amount'],
                data: payments.map((p) {
                  return [
                    p['date'] ?? '-',
                    p['mode'] ?? '-',
                    p['transaction_id'] ?? '-',
                    '\$${p['amount']?.toString() ?? '0.0'}'
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Total Amount: \$${totalAmount.toStringAsFixed(2)}'),
                      pw.Text('Paid Amount: \$${paidAmount.toStringAsFixed(2)}'),
                      pw.Divider(),
                      pw.Text(
                        'Due Amount: \$${(totalAmount - paidAmount).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Thank you for your business!', style: const pw.TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );

    // Save and open
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/invoice_$guestName.pdf');
    await file.writeAsBytes(await pdf.save());
    
    // Open the generated PDF
    await OpenFilex.open(file.path);
  }
}
