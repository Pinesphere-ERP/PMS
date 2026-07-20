import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/design_system/pine_background.dart';
import '../../../../core/presentation/widgets/design_system/pine_card.dart';

class OccupiedRoom {
  final String roomNumber;
  final String cottageType;
  final String guestName;
  final String bookingId;
  final String mobileNumber;
  final String checkInDate;
  final String checkOutDate;
  final String nightsStayed;
  final String nightsRemaining;
  final String guestsCount;
  final String occupancyStatus;
  final String paymentStatus;
  final String amountDue;
  final String bookingSource;
  final String housekeepingStatus;
  final String specialRequests;
  final String lastRoomService;
  final String currentBill;
  final String idVerification;
  final String assignedStaff;
  final String remarks;

  OccupiedRoom({
    required this.roomNumber,
    required this.cottageType,
    required this.guestName,
    required this.bookingId,
    required this.mobileNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nightsStayed,
    required this.nightsRemaining,
    required this.guestsCount,
    required this.occupancyStatus,
    required this.paymentStatus,
    required this.amountDue,
    required this.bookingSource,
    required this.housekeepingStatus,
    required this.specialRequests,
    required this.lastRoomService,
    required this.currentBill,
    required this.idVerification,
    required this.assignedStaff,
    required this.remarks,
  });
}

class OccupiedRoomsScreen extends StatefulWidget {
  const OccupiedRoomsScreen({super.key});

  @override
  State<OccupiedRoomsScreen> createState() => _OccupiedRoomsScreenState();
}

class _OccupiedRoomsScreenState extends State<OccupiedRoomsScreen> {
  final List<OccupiedRoom> _rooms = [
    OccupiedRoom(
      roomNumber: '302', cottageType: 'Deluxe Suite', guestName: 'John Doe', bookingId: 'BKG-10294', mobileNumber: '+1 555-0198',
      checkInDate: 'Oct 23, 2024', checkOutDate: 'Oct 26, 2024', nightsStayed: '1', nightsRemaining: '2', guestsCount: '2',
      occupancyStatus: 'Occupied', paymentStatus: 'Paid', amountDue: '\$0.00', bookingSource: 'Website',
      housekeepingStatus: 'Cleaned', specialRequests: 'Extra pillows', lastRoomService: '10:30 AM', currentBill: '\$0.00',
      idVerification: 'Verified', assignedStaff: 'Sarah (Housekeeping)', remarks: 'VIP Guest',
    ),
    OccupiedRoom(
      roomNumber: '105', cottageType: 'Twin Room', guestName: 'Alice Smith', bookingId: 'BKG-10295', mobileNumber: '+44 7700 900077',
      checkInDate: 'Oct 24, 2024', checkOutDate: 'Oct 25, 2024', nightsStayed: '0', nightsRemaining: '1', guestsCount: '1',
      occupancyStatus: 'Occupied', paymentStatus: 'Pending', amountDue: '\$85.00', bookingSource: 'Booking.com',
      housekeepingStatus: 'Requested', specialRequests: 'Late check-out', lastRoomService: '-', currentBill: '\$105.00',
      idVerification: 'Pending', assignedStaff: 'Mike', remarks: '-',
    ),
    OccupiedRoom(
      roomNumber: '212', cottageType: 'Standard King', guestName: 'Bob Johnson', bookingId: 'BKG-10296', mobileNumber: '+1 555-0102',
      checkInDate: 'Oct 21, 2024', checkOutDate: 'Oct 25, 2024', nightsStayed: '3', nightsRemaining: '1', guestsCount: '3',
      occupancyStatus: 'Occupied', paymentStatus: 'Partial', amountDue: '\$45.00', bookingSource: 'Airbnb',
      housekeepingStatus: 'Do Not Disturb', specialRequests: 'Extra bed', lastRoomService: 'Yesterday 4:00 PM', currentBill: '\$120.00',
      idVerification: 'Verified', assignedStaff: 'Sarah', remarks: 'Check AC',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                child: ListView.builder(
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildRoomCard(room),
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

  Widget _buildRoomCard(OccupiedRoom room) {
    return PineCard(
      onTap: () => _showRoomDetails(room),
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
                  room.guestName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Room: ${room.roomNumber} | ID: ${room.bookingId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildStatusChip(room.housekeepingStatus),
                    _buildStatusChip(room.paymentStatus),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${room.nightsRemaining} Nights',
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

  void _showRoomDetails(OccupiedRoom room) {
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
                        _buildStatusChip(room.occupancyStatus),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.person, 'Guest Name', room.guestName),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.phone, 'Mobile Number', room.mobileNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.meeting_room, 'Room / Cottage', '${room.roomNumber} (${room.cottageType})'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.tag, 'Booking ID', room.bookingId),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.login, 'Check-in Date', room.checkInDate),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.logout, 'Check-out Date', room.checkOutDate),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.bedtime, 'Nights', '${room.nightsStayed} Stayed, ${room.nightsRemaining} Remaining'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.group, 'Number of Guests', room.guestsCount),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.source, 'Booking Source', room.bookingSource),
                    const Divider(height: 32),
                    Text('Billing & Services', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.payment, 'Payment Status', room.paymentStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.money_off, 'Amount Due', room.amountDue, isAlert: room.amountDue != '\$0.00'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.receipt, 'Current Bill', room.currentBill),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.cleaning_services, 'Housekeeping', room.housekeepingStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.room_service, 'Last Room Service', room.lastRoomService),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.star, 'Special Requests', room.specialRequests),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.assignment_ind, 'ID Verification', room.idVerification),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.support_agent, 'Assigned Staff', room.assignedStaff),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.notes, 'Remarks', room.remarks),
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
