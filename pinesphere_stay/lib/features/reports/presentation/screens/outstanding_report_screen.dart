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
  final propertyId = ref.watch(tenantProvider) ?? '';
  if (propertyId.isEmpty) throw Exception('No property selected');
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
