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

final roomUtilizationProvider = FutureProvider.autoDispose.family<RoomUtilizationReportDto, Map<String, String>>((ref, params) async {
  final propertyId = ref.watch(tenantProvider);
  if (propertyId == null || propertyId.isEmpty) {
    await Completer<Never>().future;
  }
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
        }), loading: () => const SizedBox.shrink(), error: (err, stack) => const SizedBox.shrink())],
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
                  onPressed: () => ref.invalidate(roomUtilizationProvider(_params)),
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

  Widget _buildContent(RoomUtilizationReportDto report) {
    return CustomScrollView(
      slivers: [
        if (report.mostUtilized != null) SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverToBoxAdapter(
          child: Row(children: [
            Expanded(child: PineCard(child: Column(children: [const Icon(Icons.trending_up, color: Colors.green, size: 28), const SizedBox(height: 4), const Text('Most Utilized', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)), Text('Room ${report.mostUtilized}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green))]))),
            const SizedBox(width: 16),
            Expanded(child: PineCard(child: Column(children: [const Icon(Icons.trending_down, color: Colors.red, size: 28), const SizedBox(height: 4), const Text('Least Utilized', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)), Text('Room ${report.leastUtilized ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red))]))),
          ]),
        )),
        SliverPadding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), sliver: SliverToBoxAdapter(child: Text('Room Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)))),
        SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList.builder(
          itemCount: report.rooms.length,
          itemBuilder: (context, index) {
            final r = report.rooms[index];
            return Padding(padding: const EdgeInsets.only(bottom: 8), child: PineCard(
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
            ));
          },
        )),
        const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
      ],
    );
  }
}
