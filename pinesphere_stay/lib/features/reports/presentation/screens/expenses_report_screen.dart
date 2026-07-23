import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/tenant_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../data/reports_repository.dart';
import '../../data/report_export_service.dart';
import '../../domain/models/report_dtos.dart';

final expensesReportProvider = FutureProvider.autoDispose.family<ExpensesReportDto, Map<String, String>>((ref, params) async {
  final propertyId = ref.watch(tenantProvider) ?? '';
  if (propertyId.isEmpty) throw Exception('No property selected');
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getExpensesReport(propertyId: propertyId, startDate: params['startDate']!, endDate: params['endDate']!);
});

class ExpensesReportScreen extends ConsumerStatefulWidget {
  const ExpensesReportScreen({super.key});

  @override
  ConsumerState<ExpensesReportScreen> createState() => _ExpensesReportScreenState();
}

class _ExpensesReportScreenState extends ConsumerState<ExpensesReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Map<String, String> get _params => {
    'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
    'endDate': DateFormat('yyyy-MM-dd').format(_endDate),
  };

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(expensesReportProvider(_params));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Expenses Report'), backgroundColor: AppColors.background, elevation: 0,
        actions: [reportAsync.when(data: (r) => IconButton(icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary), onPressed: () async {
          try { await ref.read(reportExportServiceProvider).exportExpensesReportToPdf(r); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated'))); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'))); }
        }), loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink())],
      ),
      body: PineBackground(child: Column(children: [
        _buildDateFilter(),
        Expanded(child: reportAsync.when(data: _buildContent, loading: () => const Center(child: CircularProgressIndicator()), error: (e, _) => Center(child: Text('Error: $e')))),
      ])),
    );
  }

  Widget _buildDateFilter() {
    return Container(padding: const EdgeInsets.all(16), color: AppColors.surface,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}', style: Theme.of(context).textTheme.titleMedium),
        ElevatedButton.icon(onPressed: _pickDateRange, icon: const Icon(Icons.calendar_today, size: 18), label: const Text('Date Range')),
      ]));
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: DateTimeRange(start: _startDate, end: _endDate));
    if (picked != null) setState(() { _startDate = picked.start; _endDate = picked.end; });
  }

  Widget _buildContent(ExpensesReportDto report) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Expenses Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      PineCard(child: ListTile(leading: const Icon(Icons.receipt_long, color: Colors.red), title: const Text('Total Expenses'), trailing: Text('₹${report.totalExpenses.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red)))),
      if (report.byCategory.isNotEmpty) ...[const SizedBox(height: 24), Text('By Category', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16),
        PineCard(child: Column(children: report.byCategory.map((c) => ListTile(title: Text(c['category'] ?? ''), subtitle: Text('${c['count']} expenses'), trailing: Text('₹${(c['amount'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))).toList()))],
      if (report.recentExpenses.isNotEmpty) ...[const SizedBox(height: 24), Text('Recent Expenses', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 16),
        PineCard(child: Column(children: report.recentExpenses.take(10).map((e) => ListTile(title: Text(e['description'] ?? ''), subtitle: Text('${e['category']} - ${e['expense_date']}'), trailing: Text('₹${(e['amount'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)))).toList()))],
      const SizedBox(height: 48),
    ]);
  }
}
