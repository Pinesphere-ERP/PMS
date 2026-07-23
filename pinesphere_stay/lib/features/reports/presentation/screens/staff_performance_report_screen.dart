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

final staffPerformanceProvider = FutureProvider.autoDispose.family<StaffPerformanceReportDto, Map<String, String>>((ref, params) async {
  final propertyId = ref.watch(tenantProvider) ?? '';
  if (propertyId.isEmpty) throw Exception('No property selected');
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getStaffPerformance(propertyId: propertyId, startDate: params['startDate']!, endDate: params['endDate']!);
});

class StaffPerformanceReportScreen extends ConsumerStatefulWidget {
  const StaffPerformanceReportScreen({super.key});

  @override
  ConsumerState<StaffPerformanceReportScreen> createState() => _StaffPerformanceReportScreenState();
}

class _StaffPerformanceReportScreenState extends ConsumerState<StaffPerformanceReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Map<String, String> get _params => {
    'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
    'endDate': DateFormat('yyyy-MM-dd').format(_endDate),
  };

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(staffPerformanceProvider(_params));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Staff Performance'), backgroundColor: AppColors.background, elevation: 0,
        actions: [reportAsync.when(data: (r) => IconButton(icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary), onPressed: () async {
          try { await ref.read(reportExportServiceProvider).exportStaffPerformanceReportToPdf(r); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated'))); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'))); }
        }), loading: () => const SizedBox.shrink(), error: (err, stack) => const SizedBox.shrink())],
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

  Widget _buildContent(StaffPerformanceReportDto report) {
    return CustomScrollView(
      slivers: [
        SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList.list(children: [
          Text('Performance Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.3, children: [
            _buildMetricCard(Icons.check_circle, Colors.green, 'Completed', '${report.totalTasksCompleted}'),
            _buildMetricCard(Icons.pending, Colors.orange, 'Pending', '${report.totalTasksPending}'),
            _buildMetricCard(Icons.people, Colors.blue, 'Staff', '${report.staff.length}'),
            _buildMetricCard(Icons.cleaning_services, Colors.purple, 'HK Tasks', '${report.staff.fold(0, (a, s) => a + s.housekeepingTasks)}'),
          ]),
        ])),
        SliverPadding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), sliver: SliverToBoxAdapter(child: Text('Staff Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)))),
        SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList.builder(
          itemCount: report.staff.length,
          itemBuilder: (context, index) {
            final s = report.staff[index];
            return Padding(padding: const EdgeInsets.only(bottom: 8), child: PineCard(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.primaryContainer, child: Text(s.staffName.isNotEmpty ? s.staffName[0] : '?', style: const TextStyle(color: AppColors.onPrimaryContainer, fontWeight: FontWeight.bold))),
                title: Text(s.staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s.role),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  _buildMiniStat('${s.tasksCompleted}', Colors.green, 'Done'),
                  const SizedBox(width: 8),
                  _buildMiniStat('${s.tasksPending}', Colors.orange, 'Pending'),
                ]),
              ),
            ));
          },
        )),
        const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, Color color, String title, String value) {
    return PineCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: color), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 12)), Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold))])]));
  }

  Widget _buildMiniStat(String value, Color color, String label) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
    ]);
  }
}
