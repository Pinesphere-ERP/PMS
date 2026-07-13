import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';

class TodaysDeparturesScreen extends ConsumerStatefulWidget {
  const TodaysDeparturesScreen({super.key});

  @override
  ConsumerState<TodaysDeparturesScreen> createState() => _TodaysDeparturesScreenState();
}

class _TodaysDeparturesScreenState extends ConsumerState<TodaysDeparturesScreen> {
  @override
  Widget build(BuildContext context) {
    final pmsState = ref.watch(pmsProvider);
    final now = DateTime.now();
    
    // Filter bookings where checkOutDate is today OR status is 'Active' and checkOutDate <= today
    final departures = pmsState.bookings.where((booking) {
      if (DateUtils.isSameDay(booking.checkOutDate, now)) return true;
      if (booking.status == 'Active' && booking.checkOutDate.isBefore(now)) return true;
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Today\'s Departures', style: TextStyle(color: AppColors.primary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
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
              Text(
                'Expected Departures',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: departures.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flight_takeoff, size: 64, color: AppColors.outline),
                            SizedBox(height: 16),
                            Text(
                              'No departures today',
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
                        itemCount: departures.length,
                        itemBuilder: (context, index) {
                          final booking = departures[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildDepartureCard(booking),
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

  Widget _buildDepartureCard(BookingModel departure) {
    final isCheckedOut = departure.status == 'Completed';
    final checkoutStatus = isCheckedOut ? 'Checked Out' : 'Pending';
    final amountDue = departure.totalSum - departure.depositPaid;
    final isOverdue = departure.checkOutDate.isBefore(DateTime.now()) && !DateUtils.isSameDay(departure.checkOutDate, DateTime.now());
    
    return BentoCard(
      onTap: () => _showDepartureDetails(departure),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCheckedOut 
                  ? AppColors.surfaceVariant 
                  : (isOverdue ? AppColors.errorContainer : AppColors.secondaryContainer),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flight_takeoff,
              color: isCheckedOut 
                  ? AppColors.onSurfaceVariant 
                  : (isOverdue ? AppColors.error : AppColors.onSecondaryContainer),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  departure.guestName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Room: ${departure.roomNumber} | ID: ${departure.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (isOverdue && !isCheckedOut) _buildStatusChip('Overdue', isError: true),
                    _buildStatusChip(checkoutStatus),
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
                DateFormat('hh:mm a').format(departure.checkOutDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isOverdue ? AppColors.error : AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check-out',
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

  void _showDepartureDetails(BookingModel departure) {
    final amountDue = departure.totalSum - departure.depositPaid;
    final paymentStatus = departure.isPaid ? 'Paid' : (departure.depositPaid > 0 ? 'Partial' : 'Pending');
    final checkoutStatus = departure.status == 'Completed' ? 'Checked Out' : 'Pending';
    final extraCharges = departure.damageBill + departure.laundryBill + departure.miniBarBill + departure.restaurantBill;

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
          initialChildSize: 0.75,
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
                          'Departure Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusChip(checkoutStatus),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.person, 'Guest Name', departure.guestName),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.phone, 'Mobile Number', departure.guestPhone),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.meeting_room, 'Room', departure.roomNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.tag, 'Booking ID', departure.id),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.calendar_today, 'Check-in Date', DateFormat('MMM dd, yyyy').format(departure.checkInDate)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.event_busy, 'Check-out Date', DateFormat('MMM dd, yyyy').format(departure.checkOutDate)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.access_time, 'Check-out Time', DateFormat('hh:mm a').format(departure.checkOutDate)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.group, 'Number of Guests', '1'),
                    const Divider(height: 32),
                    Text(
                      'Billing Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.receipt_long, 'Total Bill', '\$${departure.totalSum.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.monetization_on, 'Amount Due', '\$${amountDue.toStringAsFixed(2)}', isAlert: amountDue > 0),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.payment, 'Payment Status', paymentStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.security, 'Security Deposit', '\$${departure.depositPaid.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.add_shopping_cart, 'Extra Charges', '\$${extraCharges.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.description, 'Invoice Status', departure.isPaid ? 'Generated' : 'Pending'),
                    const Divider(height: 32),
                    Text(
                      'Checkout Checklist',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.vpn_key, 'Key Returned', 'Pending'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.badge, 'ID Returned', 'Pending'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.cleaning_services, 'Housekeeping', 'Pending'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.hotel, 'Room Availability', departure.status == 'Completed' ? 'Cleaning' : 'Occupied'),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.feedback, 'Feedback Submitted', 'No'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.notes, 'Remarks', '-'),
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
    return Row(
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
    );
  }
}
