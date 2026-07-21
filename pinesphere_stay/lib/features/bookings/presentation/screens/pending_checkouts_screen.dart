import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';

class PendingCheckoutsScreen extends ConsumerStatefulWidget {
  const PendingCheckoutsScreen({super.key});

  @override
  ConsumerState<PendingCheckoutsScreen> createState() => _PendingCheckoutsScreenState();
}

class _PendingCheckoutsScreenState extends ConsumerState<PendingCheckoutsScreen> {
  @override
  Widget build(BuildContext context) {
    final pmsState = ref.watch(pmsProvider);
    final now = DateTime.now();

    // Filter bookings where status == 'Active' AND checkOutDate is on or before today
    final checkouts = pmsState.bookings.where((booking) {
      if (booking.status != 'Active') return false;
      return booking.checkOutDate.isBefore(now) || DateUtils.isSameDay(booking.checkOutDate, now);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Checkouts', style: TextStyle(color: AppColors.primary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
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
                'Action Required',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: checkouts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_empty, size: 64, color: AppColors.outline),
                            SizedBox(height: 16),
                            Text(
                              'No pending checkouts',
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
                        itemCount: checkouts.length,
                        itemBuilder: (context, index) {
                          final checkout = checkouts[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildCheckoutCard(checkout),
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

  Widget _buildCheckoutCard(BookingModel checkout) {
    final isOverdue = checkout.checkOutDate.isBefore(DateTime.now()) && !DateUtils.isSameDay(checkout.checkOutDate, DateTime.now());
    final amountDue = checkout.totalSum - checkout.depositPaid;

    return BentoCard(
      onTap: () => _showCheckoutDetails(checkout),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOverdue ? AppColors.errorContainer : AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.exit_to_app,
              color: isOverdue ? AppColors.error : AppColors.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkout.guestName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Room: ${checkout.roomNumber} | ID: ${checkout.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (isOverdue) _buildStatusChip('Overdue', isError: true),
                    if (amountDue > 0) _buildStatusChip('Due: \$${amountDue.toStringAsFixed(0)}', isError: true),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('hh:mm a').format(checkout.checkOutDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isOverdue ? AppColors.error : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Expected',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCheckoutDetails(BookingModel checkout) {
    final extraCharges = checkout.damageBill + checkout.laundryBill + checkout.miniBarBill + checkout.restaurantBill;
    final amountDue = checkout.totalSum - checkout.depositPaid;
    final paymentStatus = checkout.isPaid ? 'Paid' : (checkout.depositPaid > 0 ? 'Partial' : 'Pending');
    final nights = checkout.checkOutDate.difference(checkout.checkInDate).inDays;

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
                          'Checkout Details',
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
                            'Process Checkout',
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
                    _buildDetailRow(Icons.person, 'Guest Name', checkout.guestName),
                    _buildDetailRow(Icons.phone, 'Mobile Number', checkout.guestPhone),
                    _buildDetailRow(Icons.meeting_room, 'Room', checkout.roomNumber),
                    _buildDetailRow(Icons.tag, 'Booking ID', checkout.id),
                    _buildDetailRow(Icons.source, 'Booking Source', checkout.bookingSource),
                    
                    const Divider(height: 32),
                    _buildSectionHeader('Stay Details'),
                    _buildDetailRow(Icons.calendar_today, 'Check-in', DateFormat('MMM dd, yyyy').format(checkout.checkInDate)),
                    _buildDetailRow(Icons.event_busy, 'Check-out', DateFormat('MMM dd, yyyy').format(checkout.checkOutDate)),
                    _buildDetailRow(Icons.access_time, 'Expected Time', DateFormat('hh:mm a').format(checkout.checkOutDate)),
                    _buildDetailRow(Icons.bedtime, 'Nights Stayed', nights.toString()),
                    
                    const Divider(height: 32),
                    _buildSectionHeader('Billing Summary'),
                    _buildDetailRow(Icons.hotel, 'Room Charges', '\$${checkout.basePriceSum.toStringAsFixed(2)}'),
                    _buildDetailRow(Icons.add_shopping_cart, 'Additional Charges', '\$${extraCharges.toStringAsFixed(2)}'),
                    _buildDetailRow(Icons.account_balance, 'Taxes (GST)', '\$0.00'),
                    _buildDetailRow(Icons.local_offer, 'Discount', '\$0.00'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Bill', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                              Text('\$${checkout.totalSum.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Amount Paid', style: TextStyle(color: AppColors.onSurfaceVariant)),
                              Text('\$${checkout.depositPaid.toStringAsFixed(2)}', style: TextStyle(color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),
                              Text('\$${amountDue.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.payment, 'Payment Status', paymentStatus),
                    _buildDetailRow(Icons.security, 'Security Deposit', '\$${checkout.depositPaid.toStringAsFixed(2)}'),
                    _buildDetailRow(Icons.money_off, 'Deposit Refund', 'Refund Pending'),
                    
                    const Divider(height: 32),
                    _buildSectionHeader('Clearance Status'),
                    _buildDetailRow(Icons.vpn_key, 'Key Returned', 'Pending', isAlert: true),
                    _buildDetailRow(Icons.badge, 'ID Returned', 'Pending', isAlert: true),
                    _buildDetailRow(Icons.cleaning_services, 'Housekeeping Status', 'Pending', isAlert: true),
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

  Widget _buildStatusChip(String status, {bool isError = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorContainer : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isError ? AppColors.error : AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 11,
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
