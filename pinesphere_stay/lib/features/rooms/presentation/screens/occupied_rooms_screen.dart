import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pms_provider.dart';

class OccupiedRoomsScreen extends ConsumerStatefulWidget {
  const OccupiedRoomsScreen({super.key});

  @override
  ConsumerState<OccupiedRoomsScreen> createState() => _OccupiedRoomsScreenState();
}

class _OccupiedRoomsScreenState extends ConsumerState<OccupiedRoomsScreen> {
  @override
  Widget build(BuildContext context) {
    final pmsState = ref.watch(pmsProvider);

    // Active bookings
    final activeBookings = pmsState.bookings.where((b) => b.status == 'Active').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Occupied Rooms', style: TextStyle(color: AppColors.primary)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: PineBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currently Occupied',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: activeBookings.isEmpty 
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hotel, size: 64, color: AppColors.outline),
                          SizedBox(height: 16),
                          Text(
                            'No occupied rooms',
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
                      itemCount: activeBookings.length,
                      itemBuilder: (context, index) {
                        final booking = activeBookings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildRoomCard(booking),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildRoomCard(BookingModel booking) {
    final now = DateTime.now();
    final checkOut = booking.checkOutDate;
    final nightsRemaining = checkOut.difference(now).inDays > 0 ? checkOut.difference(now).inDays : 0;
    
    final paymentStatus = booking.isPaid ? 'Paid' : (booking.depositPaid > 0 ? 'Partial' : 'Pending');

    return PineCard(
      onTap: () => _showRoomDetails(booking),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hotel,
              color: AppColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.guestName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Room: ${booking.roomNumber} | ID: ${booking.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildStatusChip('Occupied'),
                    _buildStatusChip(paymentStatus),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$nightsRemaining Nights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Remaining',
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

  void _showRoomDetails(BookingModel booking) {
    final checkInStr = booking.checkInDate.toString().substring(0, 10);
    final checkOutStr = booking.checkOutDate.toString().substring(0, 10);
    final paymentStatus = booking.isPaid ? 'Paid' : (booking.depositPaid > 0 ? 'Partial' : 'Pending');
    final amountDue = booking.totalSum - booking.depositPaid;
    final amountDueStr = '\$${amountDue.toStringAsFixed(2)}';
    
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
                          'Occupied Room Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusChip('Occupied'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.person, 'Guest Name', booking.guestName),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.phone, 'Mobile Number', booking.guestPhone),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.meeting_room, 'Room', booking.roomNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.tag, 'Booking ID', booking.id),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.login, 'Check-in Date', checkInStr),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.logout, 'Check-out Date', checkOutStr),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.group, 'Number of Guests', 'Standard'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.source, 'Booking Source', booking.bookingSource),
                    const Divider(height: 32),
                    Text('Billing & Services', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.payment, 'Payment Status', paymentStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.money_off, 'Amount Due', amountDueStr, isAlert: amountDue > 0),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.receipt, 'Current Bill', '\$${booking.totalSum.toStringAsFixed(2)}'),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.cleaning_services, 'Housekeeping', 'Cleaned'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.assignment_ind, 'ID Verification', booking.guestIdProof),
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

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'occupied':
      case 'paid':
      case 'cleaned':
      case 'verified':
        bgColor = AppColors.secondaryContainer;
        textColor = AppColors.onSecondaryContainer;
        break;
      case 'pending':
      case 'partial':
      case 'do not disturb':
        bgColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        break;
      case 'requested':
        bgColor = AppColors.primaryContainer;
        textColor = AppColors.onPrimaryContainer;
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
