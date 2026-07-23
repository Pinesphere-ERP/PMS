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

final roomUtilizationProvider = FutureProvider.autoDispose.family<RoomUtilizationReportDto, Map<String, String>>((ref, params) async {
  final propertyId = ref.watch(tenantProvider) ?? '';
  if (propertyId.isEmpty) throw Exception('No property selected');
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getRoomUtilization(propertyId: propertyId, startDate: params['startDate']!, endDate: params['endDate']!);
});

class RoomUtilizationReportScreen extends ConsumerStatefulWidget {
  const RoomUtilizationReportScreen({super.key});

  @override
  ConsumerState<RoomUtilizationReportScreen> createState() => _RoomUtilizationReportScreenState();
}

class _RoomUtilizationReportScreenState extends ConsumerState<RoomUtilizationReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Map<String, String> get _params => {
    'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
    'endDate': DateFormat('yyyy-MM-dd').format(_endDate),
  };

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(roomUtilizationProvider(_params));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Room Utilization'), backgroundColor: AppColors.background, elevation: 0,
        actions: [reportAsync.when(data: (r) => IconButton(icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary), onPressed: () async {
          try { await ref.read(reportExportServiceProvider).exportRoomUtilizationReportToPdf(r); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated'))); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'))); }
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

  Widget _buildContent(RoomUtilizationReportDto report) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (report.mostUtilized != null) ...[
        Row(children: [
          Expanded(child: PineCard(child: Column(children: [const Icon(Icons.trending_up, color: Colors.green, size: 28), const SizedBox(height: 4), const Text('Most Utilized', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)), Text('Room ${report.mostUtilized}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green))]))),
          const SizedBox(width: 16),
          Expanded(child: PineCard(child: Column(children: [const Icon(Icons.trending_down, color: Colors.red, size: 28), const SizedBox(height: 4), const Text('Least Utilized', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)), Text('Room ${report.leastUtilized ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red))]))),
        ]),
        const SizedBox(height: 24),
      ],
      Text('Room Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ...report.rooms.map((r) => Padding(padding: const EdgeInsets.only(bottom: 8), child: PineCard(
        child: ListTile(
          title: Text('Room ${r.roomNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${r.roomType} | ${r.totalBookings} bookings | ${r.occupiedNights} nights'),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: r.occupancyPct >= 70 ? Colors.green.shade50 : r.occupancyPct >= 40 ? Colors.orange.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
              child: Text('${r.occupancyPct}%', style: TextStyle(fontWeight: FontWeight.bold, color: r.occupancyPct >= 70 ? Colors.green : r.occupancyPct >= 40 ? Colors.orange : Colors.red, fontSize: 12))),
            const SizedBox(height: 4),
            Text('₹${r.revenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
          ]),
        ),
      ))),
      const SizedBox(height: 48),
    ]);
  }
}
