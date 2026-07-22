import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/tenant_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../data/reports_repository.dart';
import '../../domain/models/report_dtos.dart';

final revenueReportProvider = FutureProvider.autoDispose<RevenueReportDto>((ref) async {
  final propertyId = ref.watch(tenantProvider) ?? '';
  if (propertyId.isEmpty) throw Exception('No property selected');
  final repo = ref.watch(reportsRepositoryProvider);
  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 30));
  return repo.getRevenueReport(
    propertyId: propertyId,
    startDate: DateFormat('yyyy-MM-dd').format(start),
    endDate: DateFormat('yyyy-MM-dd').format(end),
  );
});

class RevenueReportScreen extends ConsumerWidget {
  const RevenueReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(revenueReportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Revenue Report')),
      body: PineBackground(
        child: reportAsync.when(
          data: (report) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PineCard(
                child: Column(
                  children: [
                    Text('Total Revenue (Last 30 Days)', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('₹${report.totalRevenue.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('By Payment Method', style: Theme.of(context).textTheme.titleMedium),
              ...report.byPaymentMethod.map((m) => ListTile(title: Text(m['method']), trailing: Text('₹${m['revenue']?.toStringAsFixed(0)}'))),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
