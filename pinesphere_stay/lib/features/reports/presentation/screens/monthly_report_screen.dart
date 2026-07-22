import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/tenant_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../data/reports_repository.dart';
import '../../domain/models/report_dtos.dart';

final monthlyReportProvider = FutureProvider.autoDispose.family<MonthlyReportDto, DateTime>((ref, date) async {
  final propertyId = ref.watch(tenantProvider) ?? '';
  if (propertyId.isEmpty) throw Exception('No property selected');
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getMonthlyReport(propertyId: propertyId, month: date.month, year: date.year);
});

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(monthlyReportProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Report')),
      body: PineBackground(
        child: Column(
          children: [
            _buildMonthPicker(),
            Expanded(
              child: reportAsync.when(
                data: (report) => _buildContent(report),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${_selectedDate.year} - Month ${_selectedDate.month}', style: Theme.of(context).textTheme.titleMedium),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1)),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () => setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildContent(MonthlyReportDto report) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PineCard(
          child: Column(
            children: [
              ListTile(title: const Text('Total Revenue'), trailing: Text('₹${report.totalRevenue.toStringAsFixed(0)}')),
              ListTile(title: const Text('Total Expenses'), trailing: Text('₹${report.totalExpenses.toStringAsFixed(0)}')),
              ListTile(title: const Text('Occupancy'), trailing: Text('${report.occupancyPct}%')),
              ListTile(title: const Text('Bookings'), trailing: Text('${report.totalBookings}')),
              ListTile(title: const Text('Cancelled'), trailing: Text('${report.cancelledBookings}')),
            ],
          ),
        ),
      ],
    );
  }
}
