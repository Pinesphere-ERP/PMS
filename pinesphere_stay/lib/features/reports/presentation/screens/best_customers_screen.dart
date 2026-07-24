import 'dart:async';
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

final bestCustomersProvider = FutureProvider.autoDispose.family<BestCustomersReportDto, Map<String, String>>((ref, params) async {
  final propertyId = ref.watch(tenantProvider);
  if (propertyId == null || propertyId.isEmpty) {
    await Completer<Never>().future;
  }
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getBestCustomers(propertyId: propertyId, startDate: params['startDate']!, endDate: params['endDate']!);
});

class BestCustomersScreen extends ConsumerStatefulWidget {
  const BestCustomersScreen({super.key});

  @override
  ConsumerState<BestCustomersScreen> createState() => _BestCustomersScreenState();
}

class _BestCustomersScreenState extends ConsumerState<BestCustomersScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _endDate = DateTime.now();

  Map<String, String> get _params => {
    'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
    'endDate': DateFormat('yyyy-MM-dd').format(_endDate),
  };

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(bestCustomersProvider(_params));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Best Customers'), backgroundColor: AppColors.background, elevation: 0,
        actions: [reportAsync.when(data: (r) => IconButton(icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary), onPressed: () async {
          try { await ref.read(reportExportServiceProvider).exportBestCustomersReportToPdf(r); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated'))); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'))); }
        }), loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink())],
      ),
      body: PineBackground(child: Column(children: [
        _buildDateFilter(),
        Expanded(child: reportAsync.when(data: _buildContent, loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading report...', style: TextStyle(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ), error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Failed to load report', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(bestCustomersProvider(_params)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ))),
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

  Widget _buildContent(BestCustomersReportDto report) {
    if (report.customers.isEmpty) {
      return const Center(child: Text('No customer data for this period'));
    }
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: report.customers.length, itemBuilder: (context, i) {
      final c = report.customers[i];
      final isTop3 = i < 3;
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: PineCard(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isTop3 ? Colors.amber : AppColors.surfaceContainerHigh,
            child: Text('${i + 1}', style: TextStyle(color: isTop3 ? Colors.white : AppColors.onSurface, fontWeight: FontWeight.bold)),
          ),
          title: Row(children: [Text(c.guestName, style: const TextStyle(fontWeight: FontWeight.bold)), if (isTop3) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.star, color: Colors.amber, size: 18))]),
          subtitle: Text('${c.totalBookings} bookings | ${c.totalNights} nights'),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${c.totalRevenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
            Text('Avg: ₹${c.avgBookingValue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          ]),
        ),
      ));
    });
  }
}
