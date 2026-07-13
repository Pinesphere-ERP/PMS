import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import '../domain/models/kpi_dto.dart';

final reportExportServiceProvider = Provider((ref) => ReportExportService());

class ReportExportService {
  Future<void> exportToPdf(PLReportDto report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Profit & Loss Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Total Revenue: \$${report.summaryTotalRevenue.toStringAsFixed(2)}'),
              pw.Text('Total Expenses: \$${report.summaryTotalExpenses.toStringAsFixed(2)}'),
              pw.Text('Net Profit: \$${report.summaryNetProfit.toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              pw.Text('Monthly Breakdown', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Month', 'Revenue', 'Expenses', 'Profit'],
                  ...report.monthlyBreakdown.map((row) => [
                        row.month,
                        '\$${row.totalRevenue.toStringAsFixed(2)}',
                        '\$${row.totalExpenses.toStringAsFixed(2)}',
                        '\$${row.netProfit.toStringAsFixed(2)}'
                      ])
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/PL_Report.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }

  Future<void> exportToExcel(PLReportDto report) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow([TextCellValue('Profit & Loss Report')]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([TextCellValue('Total Revenue: \$${report.summaryTotalRevenue.toStringAsFixed(2)}')]);
    sheet.appendRow([TextCellValue('Total Expenses: \$${report.summaryTotalExpenses.toStringAsFixed(2)}')]);
    sheet.appendRow([TextCellValue('Net Profit: \$${report.summaryNetProfit.toStringAsFixed(2)}')]);
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([TextCellValue('Monthly Breakdown')]);
    sheet.appendRow([
      TextCellValue('Month'),
      TextCellValue('Revenue'),
      TextCellValue('Expenses'),
      TextCellValue('Profit')
    ]);

    for (var row in report.monthlyBreakdown) {
      sheet.appendRow([
        TextCellValue(row.month),
        DoubleCellValue(row.totalRevenue),
        DoubleCellValue(row.totalExpenses),
        DoubleCellValue(row.netProfit)
      ]);
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
