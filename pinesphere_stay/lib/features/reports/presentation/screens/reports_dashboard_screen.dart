import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/tenant_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../../../core/presentation/widgets/role_guard.dart';
import '../../../../core/permissions/permission_matrix.dart';
import '../../../../core/permissions/user_role.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

import '../../data/kpi_aggregation_service.dart';

class ReportsDashboardScreen extends ConsumerWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PineBackground(
        child: CustomScrollView(
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
                    const SizedBox(height: 32),
                    Text(
                      'Report Gallery',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildReportGrid(context, ref),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        'Reports Hub',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('MMM d, yyyy').format(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Key metrics for $dateStr',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, WidgetRef ref) {
    final propertyId = ref.watch(tenantProvider) ?? '';

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
      error: (_, _) => _staticMetricsGrid(context),
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
            "Today's Collection", '₹0'),
        _buildMetricCard(context, Icons.trending_up,
            AppColors.onPrimaryContainer, 'Monthly Revenue', '₹0',
            bg: AppColors.primaryContainer,
            textColor: AppColors.onPrimaryContainer),
        _buildMetricCard(
            context, Icons.bed_outlined, AppColors.secondary, 'Avg Occupancy', '0%'),
        _buildMetricCard(context, Icons.pending_actions_outlined,
            AppColors.error, 'Pending Payments', '₹0'),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, IconData icon, Color iconColor,
      String title, String value,
      {Color? bg, Color? textColor}) {
    return PineCard(
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
                                .withValues(alpha: 0.8),
                      )),
              Text(value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: textColor ?? iconColor,
                        fontWeight: FontWeight.bold,
                      )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportGrid(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRole = authState.maybeWhen(
      authenticated: (user) => user.role,
      orElse: () => UserRole.guest,
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        if (PermissionMatrix.canAccessReport(userRole, ReportType.daily))
          _buildReportNavCard(
          context,
          title: 'Daily Report',
          desc: 'Check-ins, check-outs & daily ops',
          icon: Icons.today_outlined,
          color: AppColors.primary,
          route: '/reports/daily',
        ),
        if (PermissionMatrix.canAccessReport(userRole, ReportType.monthly))
          _buildReportNavCard(
          context,
          title: 'Monthly Report',
          desc: 'Month-over-month performance',
          icon: Icons.calendar_month_outlined,
          color: Colors.blue,
          route: '/reports/monthly',
        ),
        if (PermissionMatrix.canAccessReport(userRole, ReportType.occupancy))
          _buildReportNavCard(
          context,
          title: 'Occupancy',
          desc: 'Room utilization & forecasts',
          icon: Icons.bedroom_parent_outlined,
          color: AppColors.secondary,
          route: '/reports/occupancy',
        ),
        if (PermissionMatrix.canAccessReport(userRole, ReportType.revenue))
          _buildReportNavCard(
          context,
          title: 'Revenue',
          desc: 'Income breakdown by source',
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.green,
          route: '/reports/revenue',
        ),
        if (PermissionMatrix.canAccessReport(userRole, ReportType.collection))
          _buildReportNavCard(
          context,
          title: 'Collections',
          desc: 'Cash flow & payment modes',
          icon: Icons.payments_outlined,
          color: Colors.teal,
          route: '/reports/collection',
        ),
        if (PermissionMatrix.canAccessReport(userRole, ReportType.outstanding))
          _buildReportNavCard(
          context,
          title: 'Outstanding',
          desc: 'Pending payments & ageing',
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
          route: '/reports/outstanding',
        ),
        if (PermissionMatrix.canAccessReport(userRole, ReportType.expenses))
          _buildReportNavCard(
          context,
          title: 'Expenses',
          desc: 'Categorized property expenses',
          icon: Icons.receipt_long_outlined,
          color: Colors.deepOrange,
          route: '/reports/expenses',
        ),
        if (PermissionMatrix.canAccessReport(userRole, ReportType.bestCustomers))
          _buildReportNavCard(
            context,
            title: 'Best Customers',
            desc: 'Top guests by revenue & stays',
            icon: Icons.star_border_rounded,
            color: Colors.amber.shade700,
            route: '/reports/best-customers',
          ),
        if (PermissionMatrix.canAccessReport(userRole, ReportType.roomUtilization))
          _buildReportNavCard(
            context,
            title: 'Room Utilization',
            desc: 'Performance per room',
            icon: Icons.meeting_room_outlined,
            color: Colors.indigo,
            route: '/reports/room-utilization',
          ),
        if (PermissionMatrix.canAccessReport(userRole, ReportType.staffPerformance))
          _buildReportNavCard(
            context,
            title: 'Staff Performance',
            desc: 'Task completion & productivity',
            icon: Icons.badge_outlined,
            color: Colors.purple,
            route: '/reports/staff-performance',
          ),
        // Note: Profit & Loss uses a different RoleGuard since it's older
        RoleGuard(
          module: Module.reports,
          minimumLevel: AccessLevel.full,
          fallback: const SizedBox.shrink(),
          child: _buildReportNavCard(
            context,
            title: 'Profit & Loss',
            desc: 'Comprehensive financial statement',
            icon: Icons.insert_chart_outlined_rounded,
            color: Colors.blueGrey,
            route: '/pl-report',
          ),
        ),
      ],
    );
  }

  Widget _buildReportNavCard(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
        child: PineCard(
          backgroundColor: AppColors.surfaceContainerLowest,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}k';
    }
    return NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(amount);
  }
}
