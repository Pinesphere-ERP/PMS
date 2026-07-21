import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';

class PendingPaymentsScreen extends ConsumerStatefulWidget {
  const PendingPaymentsScreen({super.key});

  @override
  ConsumerState<PendingPaymentsScreen> createState() => _PendingPaymentsScreenState();
}

class _PendingPaymentsScreenState extends ConsumerState<PendingPaymentsScreen> {
  @override
  Widget build(BuildContext context) {
    final pmsState = ref.watch(pmsProvider);

    // Filter bookings where isPaid == false (has outstanding payment)
    final payments = pmsState.bookings.where((booking) {
      return !booking.isPaid && (booking.totalSum - booking.depositPaid) > 0;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Pending Payments', style: TextStyle(color: AppColors.primary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Outstanding Dues',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: payments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: AppColors.outline),
                            SizedBox(height: 16),
                            Text(
                              'No pending payments',
                              style: TextStyle(
                                color: AppColors.outline,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildPaymentCard(payment),
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

  Widget _buildPaymentCard(BookingModel payment) {
    final amountDue = payment.totalSum - payment.depositPaid;
    final isOverdue = payment.checkOutDate.isBefore(DateTime.now()) && !DateUtils.isSameDay(payment.checkOutDate, DateTime.now());
    final paymentStatus = payment.depositPaid > 0 ? 'Partial' : 'Pending';

    return BentoCard(
      onTap: () => _showPaymentDetails(payment),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppColors.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.guestName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Room: ${payment.roomNumber} | ID: ${payment.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(paymentStatus, isOverdue: isOverdue),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountColumn('Total Bill', '\$${payment.totalSum.toStringAsFixed(2)}', isHighlight: false),
              _buildAmountColumn('Paid', '\$${payment.depositPaid.toStringAsFixed(2)}', isHighlight: false),
              _buildAmountColumn('Balance Due', '\$${amountDue.toStringAsFixed(2)}', isHighlight: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.outline),
              const SizedBox(width: 6),
              Text(
                'Due: ${DateFormat('MMM dd, yyyy').format(payment.checkOutDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isOverdue ? AppColors.error : AppColors.onSurfaceVariant,
                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountColumn(String label, String amount, {required bool isHighlight}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isHighlight ? AppColors.error : AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, {bool isOverdue = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOverdue ? AppColors.errorContainer : AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isOverdue ? 'Overdue' : status,
        style: TextStyle(
          color: isOverdue ? AppColors.error : AppColors.onSecondaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  void _showPaymentDetails(BookingModel payment) {
    final amountDue = payment.totalSum - payment.depositPaid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Collection',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Collect Payment',
                            style: TextStyle(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Guest Information'),
                    _buildDetailRow(Icons.person, 'Guest Name', payment.guestName),
                    _buildDetailRow(Icons.phone, 'Mobile Number', payment.guestPhone),
                    _buildDetailRow(Icons.meeting_room, 'Room', payment.roomNumber),
                    _buildDetailRow(Icons.tag, 'Booking ID', payment.id),
                    
                    const Divider(height: 32),
                    _buildSectionHeader('Stay Details'),
                    _buildDetailRow(Icons.calendar_today, 'Check-in', DateFormat('MMM dd, yyyy').format(payment.checkInDate)),
                    _buildDetailRow(Icons.event_busy, 'Check-out', DateFormat('MMM dd, yyyy').format(payment.checkOutDate)),
                    
                    const Divider(height: 32),
                    _buildSectionHeader('Payment Summary'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Bill Amount', style: TextStyle(color: AppColors.onSurface)),
                              Text('\$${payment.totalSum.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Amount Paid', style: TextStyle(color: AppColors.onSurfaceVariant)),
                              Text('\$${payment.depositPaid.toStringAsFixed(2)}', style: TextStyle(color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.error)),
                              Text('\$${amountDue.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.error)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.calendar_month, 'Due Date', DateFormat('MMM dd, yyyy').format(payment.checkOutDate), isAlert: payment.checkOutDate.isBefore(DateTime.now())),
                    _buildDetailRow(Icons.history, 'Previous Payment', payment.depositPaid > 0 ? 'Cash' : '-'),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isAlert ? AppColors.error : AppColors.outline),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isAlert ? AppColors.error : AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
