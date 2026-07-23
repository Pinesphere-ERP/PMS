import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/core/files/file_storage_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import '../domain/models/kpi_dto.dart';
import '../domain/models/report_dtos.dart';

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

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/PL_Report.pdf');
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

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/PL_Report.xlsx');
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    }
  }

  Future<void> exportDailyReportToPdf(DailyReportDto report) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    
    final primaryColor = PdfColor.fromHex('#004D40');

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Pinesphere Stay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('Daily Report: ${report.reportDate}', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
              pw.SizedBox(height: 16),
              pw.Divider(color: primaryColor, thickness: 2),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard('Check-ins', report.totalCheckins.toDouble(), primaryColor),
                  _buildSummaryCard('Check-outs', report.totalCheckouts.toDouble(), PdfColors.orange800),
                  _buildSummaryCard('Revenue', report.revenueCollected, PdfColors.green800),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard('Occupancy', report.occupancyPct, PdfColors.blue800),
                  _buildSummaryCard('Pending', report.pendingPayments, PdfColors.red800),
                  _buildSummaryCard('New Bookings', report.newBookings.toDouble(), primaryColor),
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/Daily_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> exportMonthlyReportToPdf(MonthlyReportDto report) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final primaryColor = PdfColor.fromHex('#004D40');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, customPattern: '₹ #,##0.00');

    final months = ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Pinesphere Stay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Monthly Report: ${months[report.month]} ${report.year}', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 16),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ]),
        ]),
        build: (context) => [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _buildSummaryCard('Total Bookings', report.totalBookings.toDouble(), primaryColor),
            _buildSummaryCard('Occupancy', report.occupancyPct, PdfColors.blue800),
            _buildSummaryCard('Revenue', report.totalRevenue, PdfColors.green800),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _buildSummaryCard('Collected', report.totalCollected, PdfColors.green800),
            _buildSummaryCard('Outstanding', report.totalOutstanding, PdfColors.red800),
            _buildSummaryCard('Expenses', report.totalExpenses, PdfColors.orange800),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _buildSummaryCard('Revenue Growth', report.revenueGrowthPct, PdfColors.teal800),
            _buildSummaryCard('Prev Month Rev', report.prevMonthRevenue, PdfColors.grey700),
          ]),
          if (report.dailyRevenueTrend.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('Daily Revenue Trend', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              headers: ['Date', 'Revenue', 'Bookings'],
              data: report.dailyRevenueTrend.map((r) => [
                r['date']?.toString() ?? '',
                currencyFormat.format(r['revenue'] ?? 0),
                '${r['bookings'] ?? 0}',
              ]).toList(),
            ),
          ],
        ],
      ),
    );

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/Monthly_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> exportOccupancyReportToPdf(OccupancyReportDto report) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final primaryColor = PdfColor.fromHex('#004D40');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Pinesphere Stay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Occupancy Report: ${report.startDate} to ${report.endDate}', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 16),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ]),
        ]),
        build: (context) => [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _buildSummaryCard('Avg Occupancy', report.avgOccupancyPct, primaryColor),
            _buildSummaryCard('Total Rooms', report.totalRooms.toDouble(), PdfColors.blue800),
            _buildSummaryCard('Reserved Today', report.reservedRoomsToday.toDouble(), PdfColors.orange800),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _buildSummaryCard('Occupied Nights', report.occupiedRoomNights.toDouble(), PdfColors.green800),
            _buildSummaryCard('Available Nights', report.availableRoomNights.toDouble(), PdfColors.grey700),
          ]),
          if (report.byRoomType.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('By Room Type', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              headers: ['Room Type', 'Total', 'Occupied', 'Vacant', 'Occupancy %'],
              data: report.byRoomType.map((r) => [
                r['room_type']?.toString() ?? '',
                '${r['total'] ?? 0}',
                '${r['occupied'] ?? 0}',
                '${r['vacant'] ?? 0}',
                '${r['occupancy_pct'] ?? 0}%',
              ]).toList(),
            ),
          ],
        ],
      ),
    );

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/Occupancy_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> exportRevenueReportToPdf(RevenueReportDto report) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final primaryColor = PdfColor.fromHex('#004D40');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, customPattern: '₹ #,##0.00');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Pinesphere Stay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Revenue Report: ${report.startDate} to ${report.endDate}', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 16),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ]),
        ]),
        build: (context) => [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _buildSummaryCard('Total Revenue', report.totalRevenue, primaryColor),
            _buildSummaryCard('Taxes Collected', report.taxesCollected, PdfColors.blue800),
            _buildSummaryCard('Discounts', report.discountsGiven, PdfColors.orange800),
          ]),
          if (report.byRoomType.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('Revenue by Room Type', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              headers: ['Room Type', 'Bookings', 'Room Rent', 'Addons', 'Total'],
              data: report.byRoomType.map((r) => [
                r['room_type']?.toString() ?? '',
                '${r['bookings'] ?? 0}',
                currencyFormat.format(r['room_rent'] ?? 0),
                currencyFormat.format(r['addons'] ?? 0),
                currencyFormat.format(r['total'] ?? 0),
              ]).toList(),
            ),
          ],
          if (report.byBookingSource.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('Revenue by Booking Source', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              headers: ['Source', 'Bookings', 'Revenue'],
              data: report.byBookingSource.map((r) => [
                r['source']?.toString() ?? '',
                '${r['bookings'] ?? 0}',
                currencyFormat.format(r['revenue'] ?? 0),
              ]).toList(),
            ),
          ],
        ],
      ),
    );

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/Revenue_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> exportCollectionReportToPdf(CollectionReportDto report) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final primaryColor = PdfColor.fromHex('#004D40');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, customPattern: '₹ #,##0.00');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Pinesphere Stay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Collection Report: ${report.startDate} to ${report.endDate}', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 16),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ]),
        ]),
        build: (context) => [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _buildSummaryCard('Total Collections', report.totalCollections, primaryColor),
            _buildSummaryCard('Cash', report.cashCollections, PdfColors.green800),
            _buildSummaryCard('Card', report.cardCollections, PdfColors.blue800),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _buildSummaryCard('UPI', report.upiCollections, PdfColors.teal800),
            _buildSummaryCard('Bank Transfer', report.bankTransferCollections, PdfColors.purple800),
            _buildSummaryCard('Other', report.otherCollections, PdfColors.grey700),
          ]),
          if (report.byMethod.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('Collections by Method', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              headers: ['Method', 'Count', 'Amount'],
              data: report.byMethod.map((r) => [
                r['method']?.toString() ?? '',
                '${r['count'] ?? 0}',
                currencyFormat.format(r['amount'] ?? 0),
              ]).toList(),
            ),
          ],
        ],
      ),
    );

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/Collection_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> exportOutstandingReportToPdf(OutstandingReportDto report) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final primaryColor = PdfColor.fromHex('#004D40');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, customPattern: '₹ #,##0.00');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Pinesphere Stay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Outstanding Report: ${report.startDate} to ${report.endDate}', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 16),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ]),
        ]),
        build: (context) => [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _buildSummaryCard('Total Outstanding', report.totalOutstanding, PdfColors.red800),
            _buildSummaryCard('Pending Invoices', report.pendingInvoicesCount.toDouble(), PdfColors.orange800),
            _buildSummaryCard('Overdue', report.overdueCount.toDouble(), PdfColors.red900),
          ]),
          if (report.ageing.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('Ageing Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headers: ['Ageing Bucket', 'Amount'],
              data: report.ageing.entries.map((e) => [e.key, currencyFormat.format(e.value)]).toList(),
            ),
          ],
          if (report.customerWise.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('Customer-wise Outstanding', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              headers: ['Guest Name', 'Room', 'Amount', 'Days Pending'],
              data: report.customerWise.map((r) => [
                r['guest_name']?.toString() ?? '',
                r['room_number']?.toString() ?? '',
                currencyFormat.format(r['amount'] ?? 0),
                '${r['days_pending'] ?? 0}',
              ]).toList(),
            ),
          ],
        ],
      ),
    );

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/Outstanding_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> exportExpensesReportToPdf(ExpensesReportDto report) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final primaryColor = PdfColor.fromHex('#004D40');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, customPattern: '₹ #,##0.00');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Pinesphere Stay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Expenses Report: ${report.startDate} to ${report.endDate}', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
          pw.SizedBox(height: 8),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 16),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ]),
        ]),
        build: (context) => [
          _buildSummaryCard('Total Expenses', report.totalExpenses, PdfColors.red800),
          if (report.byCategory.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('By Category', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              headers: ['Category', 'Count', 'Total'],
              data: report.byCategory.map((r) => [
                r['category']?.toString() ?? '',
                '${r['count'] ?? 0}',
                currencyFormat.format(r['total'] ?? 0),
              ]).toList(),
            ),
          ],
          if (report.recentExpenses.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text('Recent Expenses', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerRight,
              headerAlignment: pw.Alignment.centerRight,
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
              headers: ['Date', 'Category', 'Description', 'Amount'],
              data: report.recentExpenses.map((e) => [
                e.expenseDate,
                e.category,
                e.description.length > 30 ? '${e.description.substring(0, 30)}...' : e.description,
                currencyFormat.format(e.amount),
              ]).toList(),
            ),
          ],
        ],
      ),
    );

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/Expenses_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> exportBestCustomersReportToPdf(BestCustomersReportDto report) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final primaryColor = PdfColor.fromHex('#004D40');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, customPattern: '₹ #,##0.00');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Pinesphere Stay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Best Customers Report', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
          pw.Text('${report.startDate} to ${report.endDate}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 8),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 16),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ]),
        ]),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            context: context,
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.centerRight,
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
            headers: ['#', 'Guest Name', 'Bookings', 'Nights', 'Total Revenue', 'Avg Value'],
            data: List.generate(report.customers.length, (i) {
              final c = report.customers[i];
              return [
                '${i + 1}',
                c.guestName,
                '${c.totalBookings}',
                '${c.totalNights}',
                currencyFormat.format(c.totalRevenue),
                currencyFormat.format(c.avgBookingValue),
              ];
            }),
          ),
        ],
      ),
    );

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/Best_Customers_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> exportRoomUtilizationReportToPdf(RoomUtilizationReportDto report) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final primaryColor = PdfColor.fromHex('#004D40');
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, customPattern: '₹ #,##0.00');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Pinesphere Stay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Room Utilization Report', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
          pw.Text('${report.startDate} to ${report.endDate}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 8),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 16),
          if (report.mostUtilized != null) pw.Text('Most Utilized: Room ${report.mostUtilized}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          if (report.leastUtilized != null) pw.Text('Least Utilized: Room ${report.leastUtilized}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 8),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ]),
        ]),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            context: context,
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.centerRight,
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
            headers: ['Room', 'Type', 'Bookings', 'Occupied', 'Idle', 'Occupancy %', 'Revenue'],
            data: report.rooms.map((r) => [
              r.roomNumber,
              r.roomType,
              '${r.totalBookings}',
              '${r.occupiedNights}',
              '${r.idleDays}',
              '${r.occupancyPct}%',
              currencyFormat.format(r.revenue),
            ]).toList(),
          ),
        ],
      ),
    );

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/Room_Utilization_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> exportStaffPerformanceReportToPdf(StaffPerformanceReportDto report) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final primaryColor = PdfColor.fromHex('#004D40');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        ),
        header: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Pinesphere Stay', style: pw.TextStyle(color: primaryColor, fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text('Staff Performance Report', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
          pw.Text('${report.startDate} to ${report.endDate}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          pw.SizedBox(height: 8),
          pw.Divider(color: primaryColor, thickness: 2),
          pw.SizedBox(height: 16),
        ]),
        footer: (context) => pw.Column(children: [
          pw.Divider(color: PdfColors.grey300),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
          ]),
        ]),
        build: (context) => [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _buildSummaryCard('Tasks Completed', report.totalTasksCompleted.toDouble(), PdfColors.green800),
            _buildSummaryCard('Tasks Pending', report.totalTasksPending.toDouble(), PdfColors.orange800),
            _buildSummaryCard('Staff Count', report.staff.length.toDouble(), primaryColor),
          ]),
          pw.SizedBox(height: 24),
          pw.TableHelper.fromTextArray(
            context: context,
            cellAlignment: pw.Alignment.centerRight,
            headerAlignment: pw.Alignment.centerRight,
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
            headers: ['Staff Name', 'Role', 'Completed', 'Pending', 'HK Tasks', 'Bookings', 'Avg Hours'],
            data: report.staff.map((s) => [
              s.staffName,
              s.role,
              '${s.tasksCompleted}',
              '${s.tasksPending}',
              '${s.housekeepingTasks}',
              '${s.bookingsHandled}',
              '${s.avgTaskCompletionHours?.toStringAsFixed(1) ?? "N/A"}',
            ]).toList(),
          ),
        ],
      ),
    );

    final output = await FileStorageService().getTemporaryPath();
    final file = File('$output/Staff_Performance_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
}
