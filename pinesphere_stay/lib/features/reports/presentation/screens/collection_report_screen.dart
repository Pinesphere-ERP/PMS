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

final collectionReportProvider = FutureProvider.autoDispose.family<CollectionReportDto, Map<String, String>>((ref, params) async {
  final propertyId = ref.watch(tenantProvider);
  if (propertyId == null || propertyId.isEmpty) {
    await Completer<Never>().future;
  }
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getCollectionReport(propertyId: propertyId, startDate: params['startDate']!, endDate: params['endDate']!);
});

class CollectionReportScreen extends ConsumerStatefulWidget {
  const CollectionReportScreen({super.key});

  @override
  ConsumerState<CollectionReportScreen> createState() => _CollectionReportScreenState();
}

class _CollectionReportScreenState extends ConsumerState<CollectionReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Map<String, String> get _params => {
    'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
    'endDate': DateFormat('yyyy-MM-dd').format(_endDate),
  };

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(collectionReportProvider(_params));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Collection Report'), backgroundColor: AppColors.background, elevation: 0,
        actions: [reportAsync.when(data: (r) => IconButton(icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary), onPressed: () async {
          try { await ref.read(reportExportServiceProvider).exportCollectionReportToPdf(r); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generated'))); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'))); }
        }), loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink())],
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
                  onPressed: () => ref.invalidate(collectionReportProvider(_params)),
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

  Widget _buildContent(CollectionReportDto report) {
    return CustomScrollView(
      slivers: [
        SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList.list(children: [
          Text('Collection Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1.3, children: [
            _buildMetricCard(Icons.payments, AppColors.primary, 'Total', '₹${report.totalCollections.toStringAsFixed(0)}'),
            _buildMetricCard(Icons.money, Colors.amber, 'Cash', '₹${report.cashCollections.toStringAsFixed(0)}'),
            _buildMetricCard(Icons.credit_card, Colors.blue, 'Card', '₹${report.cardCollections.toStringAsFixed(0)}'),
            _buildMetricCard(Icons.phone_android, Colors.indigo, 'UPI', '₹${report.upiCollections.toStringAsFixed(0)}'),
          ]),
        ])),
        if (report.byMethod.isNotEmpty) ...[
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), sliver: SliverToBoxAdapter(child: Text('By Payment Method', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)))),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList.builder(
            itemCount: report.byMethod.length,
            itemBuilder: (context, index) {
              final m = report.byMethod[index];
              return ListTile(title: Text(m['method'] ?? ''), subtitle: Text('${m['count']} transactions'), trailing: Text('₹${(m['amount'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
            },
          )),
        ],
        if (report.dailyCollections.isNotEmpty) ...[
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 8), sliver: SliverToBoxAdapter(child: Text('Daily Collections', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)))),
          SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16), sliver: SliverList.builder(
            itemCount: report.dailyCollections.take(14).length,
            itemBuilder: (context, index) {
              final d = report.dailyCollections.take(14).elementAt(index);
              return ListTile(title: Text(d['date'] ?? ''), trailing: Text('₹${(d['amount'] as num).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)));
            },
          )),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, Color color, String title, String value) {
    return PineCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: color), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 12)), Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold))])]));
  }
}
