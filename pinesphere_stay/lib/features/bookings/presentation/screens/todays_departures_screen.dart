import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class TodayDeparture {
  final String bookingId;
  final String guestName;
  final String mobileNumber;
  final String roomNumber;
  final String cottageType;
  final String checkInDate;
  final String checkOutDate;
  final String checkOutTime;
  final String guestsCount;
  final String totalBill;
  final String amountDue;
  final String paymentStatus;
  final String securityDeposit;
  final String extraCharges;
  final String invoiceStatus;
  final String checkoutStatus;
  final String keyReturned;
  final String idReturned;
  final String housekeepingStatus;
  final String cottageAvailability;
  final String feedbackSubmitted;
  final String remarks;

  TodayDeparture({
    required this.bookingId,
    required this.guestName,
    required this.mobileNumber,
    required this.roomNumber,
    required this.cottageType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.checkOutTime,
    required this.guestsCount,
    required this.totalBill,
    required this.amountDue,
    required this.paymentStatus,
    required this.securityDeposit,
    required this.extraCharges,
    required this.invoiceStatus,
    required this.checkoutStatus,
    required this.keyReturned,
    required this.idReturned,
    required this.housekeepingStatus,
    required this.cottageAvailability,
    required this.feedbackSubmitted,
    required this.remarks,
  });
}

class TodaysDeparturesScreen extends StatefulWidget {
  const TodaysDeparturesScreen({super.key});

  @override
  State<TodaysDeparturesScreen> createState() => _TodaysDeparturesScreenState();
}

class _TodaysDeparturesScreenState extends State<TodaysDeparturesScreen> {
  final List<TodayDeparture> _departures = [
    TodayDeparture(
      bookingId: 'BKG-10101', guestName: 'James Smith', mobileNumber: '+1 555-0991', roomNumber: '302', cottageType: 'Deluxe Suite',
      checkInDate: 'Oct 20, 2024', checkOutDate: 'Oct 24, 2024', checkOutTime: '11:00 AM', guestsCount: '2',
      totalBill: '\$480.00', amountDue: '\$0.00', paymentStatus: 'Paid', securityDeposit: 'Refunded', extraCharges: 'None',
      invoiceStatus: 'Generated', checkoutStatus: 'Checked Out', keyReturned: 'Yes', idReturned: 'Yes',
      housekeepingStatus: 'Cleaning Started', cottageAvailability: 'Cleaning', feedbackSubmitted: 'Yes', remarks: 'Great stay',
    ),
    TodayDeparture(
      bookingId: 'BKG-10105', guestName: 'Maria Garcia', mobileNumber: '+44 7700 900011', roomNumber: '105', cottageType: 'Twin Room',
      checkInDate: 'Oct 22, 2024', checkOutDate: 'Oct 24, 2024', checkOutTime: '10:30 AM', guestsCount: '1',
      totalBill: '\$170.00', amountDue: '\$20.00', paymentStatus: 'Partial', securityDeposit: 'Refund Pending', extraCharges: 'Room Service',
      invoiceStatus: 'Pending', checkoutStatus: 'Pending', keyReturned: 'No', idReturned: 'No',
      housekeepingStatus: 'Pending', cottageAvailability: 'Occupied', feedbackSubmitted: 'No', remarks: 'Needs early checkout',
    ),
    TodayDeparture(
      bookingId: 'BKG-10112', guestName: 'David Chen', mobileNumber: '+61 400 123 789', roomNumber: '212', cottageType: 'Standard King',
      checkInDate: 'Oct 19, 2024', checkOutDate: 'Oct 24, 2024', checkOutTime: '12:00 PM', guestsCount: '3',
      totalBill: '\$475.00', amountDue: '\$0.00', paymentStatus: 'Paid', securityDeposit: 'Refund Pending', extraCharges: 'Laundry',
      invoiceStatus: 'Generated', checkoutStatus: 'Pending', keyReturned: 'No', idReturned: 'Yes',
      housekeepingStatus: 'Pending', cottageAvailability: 'Occupied', feedbackSubmitted: 'No', remarks: '-',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                child: ListView.builder(
                  itemCount: _departures.length,
                  itemBuilder: (context, index) {
                    final departure = _departures[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildDepartureCard(departure),
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

  Widget _buildDepartureCard(TodayDeparture departure) {
    return BentoCard(
      onTap: () => _showDepartureDetails(departure),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: departure.checkoutStatus == 'Checked Out' ? AppColors.surfaceContainerHighest : AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flight_takeoff,
              color: departure.checkoutStatus == 'Checked Out' ? AppColors.onSurfaceVariant : AppColors.onSecondaryContainer,
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
                  'Room: ${departure.roomNumber} | ID: ${departure.bookingId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildStatusChip(departure.checkoutStatus),
                    _buildStatusChip(departure.paymentStatus),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                departure.checkOutTime,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
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

  void _showDepartureDetails(TodayDeparture departure) {
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
                        _buildStatusChip(departure.checkoutStatus),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.person, 'Guest Name', departure.guestName),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.phone, 'Mobile Number', departure.mobileNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.meeting_room, 'Room / Cottage', '${departure.roomNumber} (${departure.cottageType})'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.tag, 'Booking ID', departure.bookingId),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.login, 'Check-in Date', departure.checkInDate),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.logout, 'Check-out Date', departure.checkOutDate),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.access_time, 'Check-out Time', departure.checkOutTime),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.group, 'Number of Guests', departure.guestsCount),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.monetization_on, 'Total Bill', departure.totalBill),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.money_off, 'Amount Due', departure.amountDue, isAlert: departure.amountDue != '\$0.00'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.payment, 'Payment Status', departure.paymentStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.account_balance_wallet, 'Security Deposit', departure.securityDeposit),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.receipt, 'Extra Charges', departure.extraCharges),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.receipt_long, 'Invoice Status', departure.invoiceStatus),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.vpn_key, 'Key Returned', departure.keyReturned),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.badge, 'ID Returned', departure.idReturned),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.cleaning_services, 'Housekeeping', departure.housekeepingStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.event_available, 'Cottage Availability', departure.cottageAvailability),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.feedback, 'Feedback Submitted', departure.feedbackSubmitted),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.notes, 'Remarks', departure.remarks),
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
      case 'checked out':
      case 'paid':
      case 'refunded':
      case 'generated':
        bgColor = AppColors.secondaryContainer;
        textColor = AppColors.onSecondaryContainer;
        break;
      case 'pending':
      case 'partial':
      case 'refund pending':
      case 'cleaning started':
        bgColor = AppColors.errorContainer;
        textColor = AppColors.onErrorContainer;
        break;
      case 'occupied':
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
