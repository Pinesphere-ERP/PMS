import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';
import '../../../../core/presentation/widgets/role_guard.dart';
import '../../../../core/permissions/permission_matrix.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/kpi_aggregation_service.dart';
import '../../domain/models/kpi_snapshot_entity.dart';

class ReportsDashboardScreen extends ConsumerWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildMetricsGrid(context, ref),
                  const SizedBox(height: 16),
                  _buildRevenueGraph(context, ref),
                  const SizedBox(height: 16),
                  _buildOccupancyDonut(context, ref),
                  const SizedBox(height: 16),
                  RoleGuard(
                    module: Module.reports,
                    minimumLevel: AccessLevel.full,
                    child: _buildPNLSection(context, ref),
                    fallback: const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  _buildTopRooms(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildExportBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        onPressed: () => context.go('/dashboard'),
      ),
      title: Text(
        'Pinesphere Stay',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceVariant,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('MMM d, yyyy').format(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports Overview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Performance data for $dateStr',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Metrics grid — reads live from KPI stream
  // ─────────────────────────────────────────────────────────

  Widget _buildMetricsGrid(BuildContext context, WidgetRef ref) {
    // Use a placeholder property ID; in production, derive from auth state.
    final authState = ref.watch(authProvider);
    final propertyId = authState.maybeWhen(
      authenticated: (user) => user.id,
      orElse: () => '',
    );

    if (propertyId.isEmpty) {
      return _staticMetricsGrid(context);
    }

    final kpiAsync = ref.watch(todaysKpiStreamProvider(propertyId: propertyId));

    return kpiAsync.when(
      data: (kpi) {
        if (kpi == null) {
          return _staticMetricsGrid(context);
        }
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard(
              context,
              Icons.payments_outlined,
              AppColors.primary,
              "Today's Collection",
              _formatCurrency(kpi.revenueRoomRent + kpi.revenueAddons),
            ),
            _buildMetricCard(
              context,
              Icons.trending_up,
              AppColors.onPrimaryContainer,
              'Room Rent Revenue',
              _formatCurrency(kpi.revenueRoomRent),
              bg: AppColors.primaryContainer,
              textColor: AppColors.onPrimaryContainer,
            ),
            _buildMetricCard(
              context,
              Icons.bed_outlined,
              AppColors.secondary,
              'Occupied',
              '${kpi.occupiedRooms} rooms',
            ),
            _buildMetricCard(
              context,
              Icons.pending_actions_outlined,
              AppColors.error,
              'Pending Payments',
              _formatCurrency(kpi.outstandingPayments),
            ),
          ],
        );
      },
      loading: () => _staticMetricsGrid(context),
      error: (_, __) => _staticMetricsGrid(context),
    );
  }

  Widget _staticMetricsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(context, Icons.payments_outlined, AppColors.primary,
            "Today's Collection", '\$0'),
        _buildMetricCard(context, Icons.trending_up,
            AppColors.onPrimaryContainer, 'Monthly Revenue', '\$0',
            bg: AppColors.primaryContainer,
            textColor: AppColors.onPrimaryContainer),
        _buildMetricCard(
            context, Icons.bed_outlined, AppColors.secondary, 'Avg Occupancy', '0%'),
        _buildMetricCard(context, Icons.pending_actions_outlined,
            AppColors.error, 'Pending Payments', '\$0'),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, IconData icon, Color iconColor,
      String title, String value,
      {Color? bg, Color? textColor}) {
    return BentoCard(
      backgroundColor: bg ?? AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color:
                            (textColor ?? AppColors.onSurfaceVariant)
                                .withOpacity(0.8),
                      )),
              Text(value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textColor ?? iconColor,
                      )),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Revenue graph — reads 7-day KPI range from ObjectBox
  // ─────────────────────────────────────────────────────────

  Widget _buildRevenueGraph(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final propertyId = authState.maybeWhen(
      authenticated: (user) => user.id,
      orElse: () => '',
    );

    List<double> weekRevenues = List.filled(7, 0);
    if (propertyId.isNotEmpty) {
      final service = ref.read(kpiAggregationServiceProvider);
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 6));
      final snapshots = service.getRange(propertyId, start, now);
      for (final snap in snapshots) {
        final dayIndex = DateTime.parse(snap.snapshotDate).difference(start).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          weekRevenues[dayIndex] = snap.revenueRoomRent + snap.revenueAddons;
        }
      }
    }

    final maxRevenue = weekRevenues.reduce((a, b) => a > b ? a : b);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return BentoCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Revenue Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Weekly',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final pct = maxRevenue > 0 ? weekRevenues[i] / maxRevenue : 0.0;
                return _buildBar(context, days[i], pct);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, String day, double percentage) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(day,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Occupancy donut — from live KPI data
  // ─────────────────────────────────────────────────────────

  Widget _buildOccupancyDonut(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final propertyId = authState.maybeWhen(
      authenticated: (user) => user.id,
      orElse: () => '',
    );

    int occupied = 0;
    int vacant = 0;
    if (propertyId.isNotEmpty) {
      final service = ref.read(kpiAggregationServiceProvider);
      final kpi = service.getTodaySnapshot(propertyId);
      if (kpi != null) {
        occupied = kpi.occupiedRooms;
        vacant = kpi.vacantRooms;
      }
    }

    final total = occupied + vacant;
    final occupancyRate = total > 0 ? occupied / total : 0.0;

    return BentoCard(
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  color: AppColors.surfaceContainerHigh,
                ),
                CircularProgressIndicator(
                  value: occupancyRate,
                  strokeWidth: 12,
                  color: AppColors.secondary,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${(occupancyRate * 100).toInt()}%',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Occupancy Rate',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.onSurface)),
                const SizedBox(height: 8),
                Text(
                  '$occupied of $total units are currently occupied.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildLegendItem(context, AppColors.secondary, 'Occupied'),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                        context, AppColors.surfaceContainerHigh, 'Vacant'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.onSurfaceVariant)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  P&L section — owner only (AccessLevel.full)
  // ─────────────────────────────────────────────────────────

  Widget _buildPNLSection(BuildContext context, WidgetRef ref) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profit & Loss',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.onSurface)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Owner Only',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: AppColors.error)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Navigate to the P&L report for multi-month breakdown, net profit, and GST data.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('View Full P&L Report'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRooms(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Top Performing Units',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.onSurface)),
            Row(
              children: [
                Text('View All',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: AppColors.primary)),
                const Icon(Icons.chevron_right, color: AppColors.primary, size: 16),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRoomRow(context, Icons.apartment, 'Room 401', 'Penthouse Suite',
            '\$12.4k', '98% Occ.'),
        const SizedBox(height: 12),
        _buildRoomRow(context, Icons.hotel, 'Room 302', 'Deluxe Garden View',
            '\$9.8k', '94% Occ.'),
        const SizedBox(height: 12),
        _buildRoomRow(context, Icons.holiday_village, 'Cabin 12',
            'Premium Forest Lodge', '\$8.2k', '89% Occ.'),
      ],
    );
  }

  Widget _buildRoomRow(BuildContext context, IconData icon, String title,
      String subtitle, String rev, String occ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.onSurface)),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rev,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(occ,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSecondaryContainer)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_as_pdf, size: 20),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.table_chart, size: 20),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}k';
    }
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount);
  }
}
