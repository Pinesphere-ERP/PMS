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

final occupancyReportProvider = FutureProvider.autoDispose.family<OccupancyReportDto, Map<String, String>>((ref, params) async {
  final propertyId = ref.watch(tenantProvider);
  if (propertyId == null || propertyId.isEmpty) {
    await Completer<Never>().future;
  }
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getOccupancyReport(
    propertyId: propertyId,
    startDate: params['startDate']!,
    endDate: params['endDate']!,
  );
});

class OccupancyReportScreen extends ConsumerStatefulWidget {
  const OccupancyReportScreen({super.key});

  @override
  ConsumerState<OccupancyReportScreen> createState() => _OccupancyReportScreenState();
}

class _OccupancyReportScreenState extends ConsumerState<OccupancyReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Map<String, String> get _params => {
    'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
    'endDate': DateFormat('yyyy-MM-dd').format(_endDate),
  };

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(occupancyReportProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Occupancy Report'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          reportAsync.when(
            data: (report) => IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
              onPressed: () async {
                try {
                  await ref.read(reportExportServiceProvider).exportOccupancyReportToPdf(report);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated successfully')));
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: PineBackground(
        child: Column(
          children: [
            _buildDateFilter(),
            Expanded(
              child: reportAsync.when(
                data: _buildContent,
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
                          onPressed: () => ref.invalidate(occupancyReportProvider(_params)),
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
            '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ElevatedButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: const Text('Date Range'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildContent(OccupancyReportDto report) {
    return CustomScrollView(
      slivers: [
        SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList.list(children: [
          _buildSectionHeader('Occupancy Overview'),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildMetricCard(Icons.bed, AppColors.primary, 'Avg Occupancy', '${report.avgOccupancyPct}%'),
              _buildMetricCard(Icons.nightlife, Colors.blue, 'Occupied Nights', '${report.occupiedRoomNights}'),
              _buildMetricCard(Icons.meeting_room, Colors.green, 'Available Nights', '${report.availableRoomNights}'),
              _buildMetricCard(Icons.event_available, Colors.orange, 'Reserved Today', '${report.reservedRoomsToday}'),
            ],
          ),
        ])),
        if (report.byRoomType.isNotEmpty) ...[
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), sliver: SliverToBoxAdapter(child: _buildSectionHeader('By Room Type'))),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList.builder(
            itemCount: report.byRoomType.length,
            itemBuilder: (context, index) {
              final t = report.byRoomType[index];
              return ListTile(
                title: Text(t['room_type'] ?? 'Unknown'),
                subtitle: Text('${t['count']} rooms'),
                trailing: Text('${t['occupancy_pct']}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              );
            },
          )),
        ],
        if (report.dailyOccupancy.isNotEmpty) ...[
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), sliver: SliverToBoxAdapter(child: _buildSectionHeader('Daily Trend'))),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList.builder(
            itemCount: report.dailyOccupancy.take(14).length,
            itemBuilder: (context, index) {
              final d = report.dailyOccupancy.take(14).elementAt(index);
              return ListTile(
                title: Text(d['date'] ?? ''),
                subtitle: Text('Occupied: ${d['occupied']} | Vacant: ${d['vacant']}'),
                trailing: Text('${d['pct']}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          )),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));
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
}
