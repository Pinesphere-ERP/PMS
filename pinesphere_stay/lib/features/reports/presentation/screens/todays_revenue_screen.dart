import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class RevenueEntry {
  final String roomNo;
  final String guestName;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime paymentTime;

  RevenueEntry({
    required this.roomNo,
    required this.guestName,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentTime,
  });
}

class TodaysRevenueScreen extends StatefulWidget {
  const TodaysRevenueScreen({super.key});

  @override
  State<TodaysRevenueScreen> createState() => _TodaysRevenueScreenState();
}

class _TodaysRevenueScreenState extends State<TodaysRevenueScreen> {
  final List<RevenueEntry> _entries = [
    RevenueEntry(
      roomNo: '101',
      guestName: 'John Doe',
      totalAmount: 500.0,
      paymentMethod: 'Credit Card',
      paymentStatus: 'Completed',
      paymentTime: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    RevenueEntry(
      roomNo: 'Cottage 3',
      guestName: 'Jane Smith',
      totalAmount: 1200.0,
      paymentMethod: 'Bank Transfer',
      paymentStatus: 'Completed',
      paymentTime: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    RevenueEntry(
      roomNo: '205',
      guestName: 'Robert Johnson',
      totalAmount: 850.0,
      paymentMethod: 'Cash',
      paymentStatus: 'Completed',
      paymentTime: DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
    ),
    RevenueEntry(
      roomNo: '104',
      guestName: 'Alice Williams',
      totalAmount: 1700.0,
      paymentMethod: 'Credit Card',
      paymentStatus: 'Completed',
      paymentTime: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final totalRevenue = _entries.fold<double>(0, (sum, item) => sum + item.totalAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Today\'s Revenue', style: TextStyle(color: AppColors.primary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(totalRevenue, currencyFormatter),
              const SizedBox(height: 24),
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildRevenueCard(entry, currencyFormatter),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalRevenue, NumberFormat formatter) {
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
            child: const Icon(Icons.account_balance, color: AppColors.onPrimaryContainer, size: 32),
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

  Widget _buildRevenueCard(RevenueEntry entry, NumberFormat formatter) {
    return BentoCard(
      onTap: () => _showRevenueDetails(entry, formatter),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.attach_money, color: AppColors.onSecondaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.guestName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Room: ${entry.roomNo} | ${DateFormat('h:mm a').format(entry.paymentTime)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(entry.totalAmount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusChip(entry.paymentStatus),
            ],
          ),
        ],
      ),
    );
  }

  void _showRevenueDetails(RevenueEntry entry, NumberFormat formatter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(entry.paymentStatus),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.person, 'Guest Name', entry.guestName),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.meeting_room, 'Room / Cottage', entry.roomNo),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.access_time, 'Payment Time', DateFormat('MMM d, y h:mm a').format(entry.paymentTime)),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.credit_card, 'Payment Method', entry.paymentMethod),
              const Divider(height: 32),
              _buildDetailRow(Icons.monetization_on, 'Total Amount', formatter.format(entry.totalAmount), highlight: true),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        bgColor = AppColors.secondaryContainer;
        textColor = AppColors.onSecondaryContainer;
        break;
      case 'failed':
        bgColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        break;
      case 'pending':
        bgColor = AppColors.tertiaryContainer;
        textColor = AppColors.onTertiaryContainer;
        break;
      default:
        bgColor = AppColors.surfaceVariant;
        textColor = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: highlight ? AppColors.primary : AppColors.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: highlight ? AppColors.primary : AppColors.onSurface,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            fontSize: highlight ? 18 : null,
          ),
        ),
      ],
    );
  }
}
