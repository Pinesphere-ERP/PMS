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

final dailyReportProvider = FutureProvider.autoDispose.family<DailyReportDto, DateTime>((ref, date) async {
  final propertyId = ref.watch(tenantProvider);
  if (propertyId == null || propertyId.isEmpty) {
    // Stay in loading state until tenantProvider resolves
    await Completer<Never>().future;
  }
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getDailyReport(
    propertyId: propertyId,
    reportDate: DateFormat('yyyy-MM-dd').format(date),
  );
});

class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(dailyReportProvider(_selectedDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Report'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          reportAsync.when(
            data: (report) => IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
              onPressed: () async {
                try {
                  await ref.read(reportExportServiceProvider).exportDailyReportToPdf(report);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated successfully')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
                  }
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: PineBackground(
        child: Column(
          children: [
            _buildDateFilter(),
            Expanded(
              child: reportAsync.when(
                data: (report) => _buildContent(report),
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
                          onPressed: () => ref.invalidate(dailyReportProvider(_selectedDate)),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM d, yyyy').format(_selectedDate),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('Change Date'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DailyReportDto report) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Operations Overview'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard(Icons.login, Colors.blue, 'Check-ins', '${report.totalCheckins}'),
            _buildMetricCard(Icons.logout, Colors.orange, 'Check-outs', '${report.totalCheckouts}'),
            _buildMetricCard(Icons.bed, Colors.purple, 'New Bookings', '${report.newBookings}'),
            _buildMetricCard(Icons.cancel, AppColors.error, 'Cancelled', '${report.cancelledBookings}'),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Room Status'),
        const SizedBox(height: 16),
        PineCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCol('Occupied', '${report.occupiedRooms}', AppColors.secondary),
              _buildStatCol('Vacant', '${report.vacantRooms}', AppColors.surfaceContainerHigh),
              _buildStatCol('Occupancy', '${report.occupancyPct}%', AppColors.primary),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Financials'),
        const SizedBox(height: 16),
        PineCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.payments, color: Colors.green),
                title: const Text('Revenue Collected'),
                trailing: Text('₹${report.revenueCollected.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: const Text('Pending Payments'),
                trailing: Text('₹${report.pendingPayments.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Housekeeping'),
        const SizedBox(height: 16),
        PineCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCol('Completed', '${report.housekeepingCompleted}', Colors.green),
              _buildStatCol('Pending', '${report.housekeepingPending}', Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMetricCard(IconData icon, Color color, String title, String value) {
    return PineCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 12)),
              Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }
}
