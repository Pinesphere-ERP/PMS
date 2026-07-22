import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';
import '../../../rooms/presentation/providers/pms_provider.dart';

class TodaysArrivalsScreen extends ConsumerStatefulWidget {
  const TodaysArrivalsScreen({super.key});

  @override
  ConsumerState<TodaysArrivalsScreen> createState() => _TodaysArrivalsScreenState();
}

class _TodaysArrivalsScreenState extends ConsumerState<TodaysArrivalsScreen> {
  @override
  Widget build(BuildContext context) {
    final pmsState = ref.watch(pmsProvider);
    final now = DateTime.now();
    
    // Filter bookings where checkInDate is today
    final arrivals = pmsState.bookings.where((booking) {
      return DateUtils.isSameDay(booking.checkInDate, now);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Today\'s Arrivals', style: TextStyle(color: AppColors.primary)),
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
                'Expected Arrivals',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: arrivals.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available, size: 64, color: AppColors.outline),
                            SizedBox(height: 16),
                            Text(
                              'No arrivals today',
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
                        itemCount: arrivals.length,
                        itemBuilder: (context, index) {
                          final booking = arrivals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _buildArrivalCard(booking),
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

  Widget _buildArrivalCard(BookingModel arrival) {
    final isCheckedIn = arrival.status == 'Active';
    final arrivalStatus = isCheckedIn ? 'Checked In' : (arrival.status == 'Upcoming' ? 'Not Arrived' : arrival.status);
    final checkInTimeStr = DateFormat('hh:mm a').format(arrival.checkInDate);
    
    return PineCard(
      onTap: () => _showArrivalDetails(arrival),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCheckedIn ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.luggage,
              color: isCheckedIn ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arrival.guestName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Room: ${arrival.roomNumber} | ID: ${arrival.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildStatusChip('Ready'), // Cottage Ready is assumed Ready
                    _buildStatusChip(arrivalStatus),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                checkInTimeStr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (!isCheckedIn)
                ElevatedButton(
                  onPressed: () {
                    context.push('/checkin', extra: {
                      'booking_id': arrival.id,
                      'guest_name': arrival.guestName,
                      'guest_phone': arrival.guestPhone,
                      'guest_email': arrival.guestEmail,
                      'room_id': arrival.roomId,
                      'room_number': arrival.roomNumber,
                      'check_in_date': arrival.checkInDate.toIso8601String(),
                      'check_out_date': arrival.checkOutDate.toIso8601String(),
                      'deposit': arrival.depositPaid,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Check In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                Text(
                  'Checked In',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

  void _showArrivalDetails(BookingModel arrival) {
    final isCheckedIn = arrival.status == 'Active';
    final arrivalStatus = isCheckedIn ? 'Checked In' : (arrival.status == 'Upcoming' ? 'Not Arrived' : arrival.status);
    final checkInTimeStr = DateFormat('hh:mm a').format(arrival.checkInDate);
    final paymentStatus = arrival.isPaid ? 'Paid' : (arrival.depositPaid > 0 ? 'Partial' : 'Pending');
    final amountDue = arrival.totalSum - arrival.depositPaid;
    final amountDueStr = '\$${amountDue.toStringAsFixed(2)}';
    final nights = arrival.checkOutDate.difference(arrival.checkInDate).inDays.toString();

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
                          'Arrival Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusChip(arrivalStatus),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.person, 'Guest Name', arrival.guestName),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.phone, 'Mobile Number', arrival.guestPhone),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.meeting_room, 'Room', arrival.roomNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.tag, 'Booking ID', arrival.id),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.access_time, 'Check-in Time', checkInTimeStr),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.group, 'Number of Guests', '1'), // Defaulting to 1
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.bedtime, 'Nights', nights),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.source, 'Booking Source', arrival.bookingSource),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.payment, 'Payment Status', paymentStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.monetization_on, 'Amount Due', amountDueStr, isAlert: amountDue > 0),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.verified, 'Booking Status', arrival.status),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.assignment_ind, 'ID Verification', 'Pending'),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.star, 'Special Requests', 'None'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.cleaning_services, 'Cottage Ready', 'Ready'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.support_agent, 'Assigned Staff', '-'),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.local_parking, 'Parking Required', 'No'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.directions_car, 'Vehicle Number', '-'),
                    const SizedBox(height: 24),
                    if (!isCheckedIn)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/checkin', extra: {
                              'booking_id': arrival.id,
                              'guest_name': arrival.guestName,
                              'guest_phone': arrival.guestPhone,
                              'guest_email': arrival.guestEmail,
                              'room_id': arrival.roomId,
                              'room_number': arrival.roomNumber,
                              'check_in_date': arrival.checkInDate.toIso8601String(),
                              'check_out_date': arrival.checkOutDate.toIso8601String(),
                              'deposit': arrival.depositPaid,
                            });
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Check In Guest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    const SizedBox(height: 16),
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
      case 'ready':
      case 'checked in':
      case 'paid':
      case 'completed':
      case 'confirmed':
        bgColor = AppColors.secondaryContainer;
        textColor = AppColors.onSecondaryContainer;
        break;
      case 'cleaning':
      case 'pending':
      case 'partial':
      case 'not arrived':
        bgColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        break;
      case 'maintenance':
      case 'arrived':
      case 'active':
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
