import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class TodayArrival {
  final String bookingId;
  final String guestName;
  final String mobileNumber;
  final String roomNumber;
  final String cottageType;
  final String checkInTime;
  final String guestsCount;
  final String nights;
  final String bookingSource;
  final String paymentStatus;
  final String amountDue;
  final String bookingStatus;
  final String specialRequests;
  final String idVerification;
  final String assignedStaff;
  final String cottageReady;
  final String arrivalStatus;
  final String parkingRequired;
  final String vehicleNumber;

  TodayArrival({
    required this.bookingId,
    required this.guestName,
    required this.mobileNumber,
    required this.roomNumber,
    required this.cottageType,
    required this.checkInTime,
    required this.guestsCount,
    required this.nights,
    required this.bookingSource,
    required this.paymentStatus,
    required this.amountDue,
    required this.bookingStatus,
    required this.specialRequests,
    required this.idVerification,
    required this.assignedStaff,
    required this.cottageReady,
    required this.arrivalStatus,
    required this.parkingRequired,
    required this.vehicleNumber,
  });
}

class TodaysArrivalsScreen extends StatefulWidget {
  const TodaysArrivalsScreen({super.key});

  @override
  State<TodaysArrivalsScreen> createState() => _TodaysArrivalsScreenState();
}

class _TodaysArrivalsScreenState extends State<TodaysArrivalsScreen> {
  final List<TodayArrival> _arrivals = [
    TodayArrival(
      bookingId: 'BKG-10294', guestName: 'John Doe', mobileNumber: '+1 555-0198', roomNumber: '302', cottageType: 'Deluxe Suite',
      checkInTime: '14:00', guestsCount: '2', nights: '3', bookingSource: 'Website', paymentStatus: 'Paid', amountDue: '\$0.00',
      bookingStatus: 'Confirmed', specialRequests: 'Honeymoon setup', idVerification: 'Completed', assignedStaff: 'Sarah (Housekeeping)',
      cottageReady: 'Ready', arrivalStatus: 'Not Arrived', parkingRequired: 'Yes', vehicleNumber: 'ABC-1234',
    ),
    TodayArrival(
      bookingId: 'BKG-10295', guestName: 'Alice Smith', mobileNumber: '+44 7700 900077', roomNumber: '105', cottageType: 'Twin Room',
      checkInTime: '15:30', guestsCount: '1', nights: '1', bookingSource: 'Booking.com', paymentStatus: 'Pending', amountDue: '\$85.00',
      bookingStatus: 'Confirmed', specialRequests: 'None', idVerification: 'Pending', assignedStaff: 'Mike',
      cottageReady: 'Cleaning', arrivalStatus: 'Not Arrived', parkingRequired: 'No', vehicleNumber: '-',
    ),
    TodayArrival(
      bookingId: 'BKG-10296', guestName: 'Bob Johnson', mobileNumber: '+1 555-0102', roomNumber: '212', cottageType: 'Standard King',
      checkInTime: '13:00', guestsCount: '2 (1 child)', nights: '2', bookingSource: 'Airbnb', paymentStatus: 'Partial', amountDue: '\$45.00',
      bookingStatus: 'Confirmed', specialRequests: 'Extra bed', idVerification: 'Completed', assignedStaff: 'Sarah',
      cottageReady: 'Maintenance', arrivalStatus: 'Arrived', parkingRequired: 'Yes', vehicleNumber: 'XYZ-9876',
    ),
    TodayArrival(
      bookingId: 'BKG-10297', guestName: 'Emma Davis', mobileNumber: '+61 400 123 456', roomNumber: '401', cottageType: 'Penthouse',
      checkInTime: '16:00', guestsCount: '4', nights: '5', bookingSource: 'Walk-in', paymentStatus: 'Paid', amountDue: '\$0.00',
      bookingStatus: 'Confirmed', specialRequests: 'None', idVerification: 'Completed', assignedStaff: 'Jane (Manager)',
      cottageReady: 'Ready', arrivalStatus: 'Checked In', parkingRequired: 'Yes', vehicleNumber: 'DEF-5678',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
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
                child: ListView.builder(
                  itemCount: _arrivals.length,
                  itemBuilder: (context, index) {
                    final arrival = _arrivals[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildArrivalCard(arrival),
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

  Widget _buildArrivalCard(TodayArrival arrival) {
    return BentoCard(
      onTap: () => _showArrivalDetails(arrival),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: arrival.arrivalStatus == 'Checked In' ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.luggage,
              color: arrival.arrivalStatus == 'Checked In' ? AppColors.onPrimaryContainer : AppColors.onSurfaceVariant,
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
                  'Room: ${arrival.roomNumber} | ID: ${arrival.bookingId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildStatusChip(arrival.cottageReady),
                    _buildStatusChip(arrival.arrivalStatus),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                arrival.checkInTime,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check-in',
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

  void _showArrivalDetails(TodayArrival arrival) {
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
                        _buildStatusChip(arrival.arrivalStatus),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.person, 'Guest Name', arrival.guestName),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.phone, 'Mobile Number', arrival.mobileNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.meeting_room, 'Room / Cottage', '${arrival.roomNumber} (${arrival.cottageType})'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.tag, 'Booking ID', arrival.bookingId),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.access_time, 'Check-in Time', arrival.checkInTime),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.group, 'Number of Guests', arrival.guestsCount),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.bedtime, 'Nights', arrival.nights),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.source, 'Booking Source', arrival.bookingSource),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.payment, 'Payment Status', arrival.paymentStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.monetization_on, 'Amount Due', arrival.amountDue, isAlert: arrival.amountDue != '\$0.00'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.verified, 'Booking Status', arrival.bookingStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.assignment_ind, 'ID Verification', arrival.idVerification),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.star, 'Special Requests', arrival.specialRequests),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.cleaning_services, 'Cottage Ready', arrival.cottageReady),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.support_agent, 'Assigned Staff', arrival.assignedStaff),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.local_parking, 'Parking Required', arrival.parkingRequired),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.directions_car, 'Vehicle Number', arrival.vehicleNumber),
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
