import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/kpi_aggregation_service.dart';

class TodaysRevenueScreen extends ConsumerWidget {
  const TodaysRevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final propertyId = authState.maybeWhen(
      authenticated: (user) => user.id,
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Today\'s Revenue',
            style: TextStyle(color: AppColors.primary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: propertyId.isEmpty
            ? const Center(child: Text('Please log in to view revenue.'))
            : _RevenueBody(propertyId: propertyId),
      ),
    );
  }
}

class _RevenueBody extends ConsumerWidget {
  final String propertyId;

  const _RevenueBody({required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(todaysKpiStreamProvider(propertyId: propertyId));
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return kpiAsync.when(
      data: (kpi) {
        final totalRevenue = kpi != null
            ? kpi.revenueRoomRent + kpi.revenueAddons
            : 0.0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(
                totalRevenue: totalRevenue,
                formatter: currencyFormatter,
              ),
              const SizedBox(height: 24),
              // GST section — owner/accountant only
              if (kpi != null && kpi.gstCollected > 0) ...[
                _GstSummaryCard(gstAmount: kpi.gstCollected, formatter: currencyFormatter),
                const SizedBox(height: 16),
              ],
              Text(
                'Today\'s KPI Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              if (kpi != null)
                Expanded(
                  child: ListView(
                    children: [
                      _kpiRow(Icons.hotel, 'Room Rent Revenue',
                          _formatCurrency(kpi.revenueRoomRent, currencyFormatter)),
                      const SizedBox(height: 12),
                      _kpiRow(Icons.local_cafe, 'Addon Revenue',
                          _formatCurrency(kpi.revenueAddons, currencyFormatter)),
                      const SizedBox(height: 12),
                      _kpiRow(Icons.receipt, 'Expenses',
                          _formatCurrency(kpi.expensesAmount, currencyFormatter)),
                      const SizedBox(height: 12),
                      _kpiRow(Icons.pending_actions, 'Outstanding',
                          _formatCurrency(kpi.outstandingPayments, currencyFormatter)),
                      const SizedBox(height: 12),
                      _kpiRow(Icons.bed, 'Occupied Rooms',
                          '${kpi.occupiedRooms}'),
                      const SizedBox(height: 12),
                      _kpiRow(Icons.bed_outlined, 'Vacant Rooms',
                          '${kpi.vacantRooms}'),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 48, color: AppColors.outline),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet today',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'KPI data updates automatically as payments are recorded.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.outline),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  String _formatCurrency(double amount, NumberFormat formatter) {
    return formatter.format(amount);
  }

  Widget _kpiRow(IconData icon, String label, String value) {
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
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.onSecondaryContainer, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalRevenue;
  final NumberFormat formatter;

  const _SummaryCard({required this.totalRevenue, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance,
                color: AppColors.onPrimaryContainer, size: 32),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Revenue',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                formatter.format(totalRevenue),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GstSummaryCard extends StatelessWidget {
  final double gstAmount;
  final NumberFormat formatter;

  const _GstSummaryCard({required this.gstAmount, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long,
                color: AppColors.onTertiaryContainer, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GST Collected Today',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        )),
                Text(
                  formatter.format(gstAmount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
