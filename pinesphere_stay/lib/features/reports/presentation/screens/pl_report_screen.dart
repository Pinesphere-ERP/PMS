import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/tenant_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/empty_state_widget.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';

import '../../data/reports_repository.dart';
import '../../domain/models/kpi_dto.dart';

final plReportProvider = FutureProvider.autoDispose<PLReportDto>((ref) async {
  final propertyId = ref.watch(tenantProvider) ?? '';
  if (propertyId.isEmpty) throw Exception('No property ID');

  final now = DateTime.now();
  final startDate = DateFormat('yyyy-MM-dd').format(DateTime(now.year, 1, 1));
  final endDate = DateFormat('yyyy-MM-dd').format(now);

  return ref.watch(reportsRepositoryProvider).getPLReport(
    propertyId: propertyId,
    startDate: startDate,
    endDate: endDate,
  );
});

class PLReportScreen extends ConsumerWidget {
  const PLReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(plReportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Profit & Loss Report',
            style: TextStyle(color: AppColors.primary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: PineBackground(
        child: reportAsync.when(
          data: (report) => _buildReportView(context, report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Error',
          message: error.toString(),
        ),
      ),
        ),
    );
  }

  Widget _buildReportView(BuildContext context, PLReportDto report) {
    final formatCurrency = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PineCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Summary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildSummaryRow('Total Revenue', formatCurrency.format(report.summaryTotalRevenue), AppColors.primary),
              const SizedBox(height: 8),
              _buildSummaryRow('Total Expenses', formatCurrency.format(report.summaryTotalExpenses), AppColors.error),
              const Divider(height: 32),
              _buildSummaryRow('Net Profit', formatCurrency.format(report.summaryNetProfit), AppColors.secondary),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Monthly Breakdown', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ...report.monthlyBreakdown.map((monthData) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PineCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(monthData.month, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Revenue', formatCurrency.format(monthData.totalRevenue), AppColors.primary),
                    const SizedBox(height: 4),
                    _buildSummaryRow('Expenses', formatCurrency.format(monthData.totalExpenses), AppColors.error),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Profit', formatCurrency.format(monthData.netProfit), AppColors.secondary),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
