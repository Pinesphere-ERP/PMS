import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../domain/models/kpi_dto.dart';

final reportExportServiceProvider = Provider((ref) => ReportExportService());

class ReportExportService {
  Future<void> exportToPdf(PLReportDto report) async {
    final pdf = pw.Document();
    
    // Load fonts
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    
    final primaryColor = PdfColor.fromHex('#004D40');
    final accentColor = PdfColor.fromHex('#F5F5F5');
    
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, customPattern: '₹ #,##0.00');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
          ),
        ),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Pinesphere Stay',
                  style: pw.TextStyle(
                    color: primaryColor,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Profit & Loss Statement',
                  style: pw.TextStyle(
                    fontSize: 18,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Period: ${report.periodStart} to ${report.periodEnd}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: primaryColor, thickness: 2),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated automatically by Pinesphere PMS on ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Summary Cards
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryCard('Total Revenue', report.summaryTotalRevenue, primaryColor),
              _buildSummaryCard('Total Expenses', report.summaryTotalExpenses, PdfColors.red800),
              _buildSummaryCard('Net Profit', report.summaryNetProfit, PdfColors.green800),
            ],
          ),
          pw.SizedBox(height: 32),
          pw.Text('Monthly Breakdown', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          pw.SizedBox(height: 12),
          
          // Data Table
          pw.TableHelper.fromTextArray(
            context: context,
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.centerRight,
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
            ),
            oddRowDecoration: pw.BoxDecoration(color: accentColor),
            headers: <String>[
              'Month', 'Room Rent', 'Addons', 'Total Rev', 'Expenses', 'Profit', 'GST', 'Pending'
            ],
            data: <List<String>>[
              ...report.monthlyBreakdown.map((row) => <String>[
                row.month,
                currencyFormat.format(row.totalRoomRent),
                currencyFormat.format(row.totalAddons),
                currencyFormat.format(row.totalRevenue),
                currencyFormat.format(row.totalExpenses),
                currencyFormat.format(row.netProfit),
                currencyFormat.format(row.gstCollected),
                currencyFormat.format(row.outstanding)
              ]),
            ],
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/PL_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  pw.Widget _buildSummaryCard(String title, double amount, PdfColor color) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, customPattern: '₹ #,##0.00');
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color.shade(.2), width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(
            currencyFormat.format(amount),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> exportToExcel(PLReportDto report) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Define styles
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#004D40'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
    );

    final boldStyle = CellStyle(bold: true);

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Pinesphere Stay - Profit & Loss Statement');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;
    
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Period: ${report.periodStart} to ${report.periodEnd}');
    
    sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Total Revenue:');
    sheet.cell(CellIndex.indexByString('B4')).value = DoubleCellValue(report.summaryTotalRevenue);
    sheet.cell(CellIndex.indexByString('B4')).cellStyle = boldStyle;

    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Total Expenses:');
    sheet.cell(CellIndex.indexByString('B5')).value = DoubleCellValue(report.summaryTotalExpenses);
    sheet.cell(CellIndex.indexByString('B5')).cellStyle = boldStyle;

    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Net Profit:');
    sheet.cell(CellIndex.indexByString('B6')).value = DoubleCellValue(report.summaryNetProfit);
    sheet.cell(CellIndex.indexByString('B6')).cellStyle = boldStyle;

    sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Monthly Breakdown');
    sheet.cell(CellIndex.indexByString('A8')).cellStyle = boldStyle;

    final headers = ['Month', 'Room Rent', 'Addons', 'Total Revenue', 'Total Expenses', 'Net Profit', 'GST Collected', 'Outstanding'];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    
    // Apply header style
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 8)).cellStyle = headerStyle;
    }

    // Table rows
    for (var row in report.monthlyBreakdown) {
      sheet.appendRow([
        TextCellValue(row.month),
        DoubleCellValue(row.totalRoomRent),
        DoubleCellValue(row.totalAddons),
        DoubleCellValue(row.totalRevenue),
        DoubleCellValue(row.totalExpenses),
        DoubleCellValue(row.netProfit),
        DoubleCellValue(row.gstCollected),
        DoubleCellValue(row.outstanding),
      ]);
    }
    
    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 18.0);
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/PL_Report.xlsx');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    }
  }
}
