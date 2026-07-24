import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/tenant_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../data/reports_repository.dart';
import '../../domain/models/report_dtos.dart';

final outstandingReportProvider = FutureProvider.autoDispose<OutstandingReportDto>((ref) async {
  final propertyId = ref.watch(tenantProvider);
  if (propertyId == null || propertyId.isEmpty) {
    await Completer<Never>().future;
  }
  final repo = ref.watch(reportsRepositoryProvider);
  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 30));
  return repo.getOutstandingReport(
    propertyId: propertyId,
    startDate: DateFormat('yyyy-MM-dd').format(start),
    endDate: DateFormat('yyyy-MM-dd').format(end),
  );
});

class OutstandingReportScreen extends ConsumerWidget {
  const OutstandingReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(outstandingReportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Outstanding Report')),
      body: PineBackground(
        child: reportAsync.when(
          data: (report) => CustomScrollView(
            slivers: [
              SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList.list(children: [
                PineCard(
                  child: Column(
                    children: [
                      Text('Total Outstanding', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('₹${report.totalOutstanding.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.error)),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [Text('Pending Invoices'), Text('${report.pendingInvoicesCount}')]),
                          Column(children: [Text('Overdue Bookings'), Text('${report.overdueCount}')]),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Customer Wise Pending', style: Theme.of(context).textTheme.titleLarge),
              ])),
              SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList.builder(
                itemCount: report.customerWise.length,
                itemBuilder: (context, index) {
                  final c = report.customerWise[index];
                  return Card(
                    child: ListTile(
                      title: Text(c['guest_name']),
                      subtitle: Text('Due: ${c['due_date']} | Ref: ${c['booking_ref']}'),
                      trailing: Text('₹${c['amount']}'),
                    ),
                  );
                },
              )),
              const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
            ],
          ),
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Loading report...', style: TextStyle(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Failed to load report', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('$err', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(outstandingReportProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
