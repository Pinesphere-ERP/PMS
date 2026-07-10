import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class PendingCheckout {
  final String roomNumber;
  final String bookingId;
  final String guestName;
  final String mobileNumber;
  final String checkInDate;
  final String checkOutDate;
  final String expectedTime;
  final String adults;
  final String children;
  final String nights;
  final String source;
  final String roomCharges;
  final String additionalCharges;
  final String taxes;
  final String discount;
  final String totalBill;
  final String amountPaid;
  final String balanceDue;
  final String paymentStatus;
  final String securityDeposit;
  final String depositRefundStatus;
  final String keyReturnStatus;
  final String idReturnStatus;
  final String housekeepingStatus;
  final String checkoutStatus;

  PendingCheckout({
    required this.roomNumber,
    required this.bookingId,
    required this.guestName,
    required this.mobileNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.expectedTime,
    required this.adults,
    required this.children,
    required this.nights,
    required this.source,
    required this.roomCharges,
    required this.additionalCharges,
    required this.taxes,
    required this.discount,
    required this.totalBill,
    required this.amountPaid,
    required this.balanceDue,
    required this.paymentStatus,
    required this.securityDeposit,
    required this.depositRefundStatus,
    required this.keyReturnStatus,
    required this.idReturnStatus,
    required this.housekeepingStatus,
    required this.checkoutStatus,
  });
}

class PendingCheckoutsScreen extends StatefulWidget {
  const PendingCheckoutsScreen({super.key});

  @override
  State<PendingCheckoutsScreen> createState() => _PendingCheckoutsScreenState();
}

class _PendingCheckoutsScreenState extends State<PendingCheckoutsScreen> {
  final List<PendingCheckout> _checkouts = [
    PendingCheckout(
      roomNumber: '302', bookingId: 'BKG-10101', guestName: 'James Smith', mobileNumber: '+1 555-0991',
      checkInDate: 'Oct 20, 2024', checkOutDate: 'Oct 24, 2024', expectedTime: '11:00 AM', adults: '2', children: '0', nights: '4',
      source: 'Website', roomCharges: '\$400.00', additionalCharges: '\$40.00', taxes: '\$40.00', discount: '\$0.00',
      totalBill: '\$480.00', amountPaid: '\$480.00', balanceDue: '\$0.00', paymentStatus: 'Paid',
      securityDeposit: '\$50.00', depositRefundStatus: 'Refund Pending', keyReturnStatus: 'Pending', idReturnStatus: 'Returned',
      housekeepingStatus: 'Cleaning Started', checkoutStatus: 'Pending',
    ),
    PendingCheckout(
      roomNumber: '105', bookingId: 'BKG-10105', guestName: 'Maria Garcia', mobileNumber: '+44 7700 900011',
      checkInDate: 'Oct 22, 2024', checkOutDate: 'Oct 24, 2024', expectedTime: '10:30 AM', adults: '1', children: '0', nights: '2',
      source: 'Booking.com', roomCharges: '\$150.00', additionalCharges: '\$10.00', taxes: '\$10.00', discount: '\$0.00',
      totalBill: '\$170.00', amountPaid: '\$150.00', balanceDue: '\$20.00', paymentStatus: 'Partial',
      securityDeposit: '\$0.00', depositRefundStatus: 'N/A', keyReturnStatus: 'Pending', idReturnStatus: 'N/A',
      housekeepingStatus: 'Pending', checkoutStatus: 'Pending',
    ),
    PendingCheckout(
      roomNumber: '212', bookingId: 'BKG-10112', guestName: 'David Chen', mobileNumber: '+61 400 123 789',
      checkInDate: 'Oct 19, 2024', checkOutDate: 'Oct 24, 2024', expectedTime: '12:00 PM', adults: '2', children: '1', nights: '5',
      source: 'Airbnb', roomCharges: '\$450.00', additionalCharges: '\$0.00', taxes: '\$45.00', discount: '\$20.00',
      totalBill: '\$475.00', amountPaid: '\$475.00', balanceDue: '\$0.00', paymentStatus: 'Paid',
      securityDeposit: '\$100.00', depositRefundStatus: 'Refund Pending', keyReturnStatus: 'Returned', idReturnStatus: 'Pending',
      housekeepingStatus: 'Pending', checkoutStatus: 'Pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Checkouts', style: TextStyle(color: AppColors.primary)),
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
                'Action Required',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _checkouts.length,
                  itemBuilder: (context, index) {
                    final checkout = _checkouts[index];
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

  Widget _buildCheckoutCard(PendingCheckout checkout) {
    return BentoCard(
      onTap: () => _showCheckoutDetails(checkout),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_bottom,
              color: AppColors.onSecondaryContainer,
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
                  'Room: ${checkout.roomNumber} | ID: ${checkout.bookingId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildStatusChip(checkout.paymentStatus),
                    if (checkout.balanceDue != '\$0.00') _buildStatusChip('Due: ${checkout.balanceDue}', isAlert: true),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                checkout.expectedTime,
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

  void _showCheckoutDetails(PendingCheckout checkout) {
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
                          'Checkout Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusChip(checkout.checkoutStatus),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.person, 'Guest Name', checkout.guestName),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.phone, 'Mobile Number', checkout.mobileNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.meeting_room, 'Room / Cottage', checkout.roomNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.tag, 'Booking ID', checkout.bookingId),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.login, 'Check-in Date', checkout.checkInDate),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.logout, 'Scheduled Check-out', checkout.checkOutDate),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.access_time, 'Expected Check-out', checkout.expectedTime),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.group, 'Guests', '${checkout.adults} Adults, ${checkout.children} Children'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.bedtime, 'Total Nights Stayed', checkout.nights),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.source, 'Booking Source', checkout.source),
                    const Divider(height: 32),
                    Text('Billing Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.receipt, 'Total Room Charges', checkout.roomCharges),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.add_shopping_cart, 'Additional Charges', checkout.additionalCharges),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.account_balance, 'Taxes', checkout.taxes),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.local_offer, 'Discount', checkout.discount),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.monetization_on, 'Total Bill Amount', checkout.totalBill),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.payment, 'Amount Paid', checkout.amountPaid),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.money_off, 'Balance Due', checkout.balanceDue, isAlert: checkout.balanceDue != '\$0.00'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.verified, 'Payment Status', checkout.paymentStatus),
                    const Divider(height: 32),
                    Text('Deposits & Verification', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.shield, 'Security Deposit', checkout.securityDeposit),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.autorenew, 'Deposit Refund Status', checkout.depositRefundStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.vpn_key, 'Key Return Status', checkout.keyReturnStatus),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.badge, 'ID Return Status', checkout.idReturnStatus),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.cleaning_services, 'Housekeeping', checkout.housekeepingStatus),
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

  Widget _buildStatusChip(String status, {bool isAlert = false}) {
    Color bgColor;
    Color textColor;

    if (isAlert) {
      bgColor = AppColors.errorContainer;
      textColor = AppColors.onErrorContainer;
    } else {
      switch (status.toLowerCase()) {
        case 'paid':
        case 'returned':
        case 'completed':
          bgColor = AppColors.secondaryContainer;
          textColor = AppColors.onSecondaryContainer;
          break;
        case 'pending':
        case 'partial':
        case 'cleaning started':
        case 'refund pending':
          bgColor = AppColors.errorContainer;
          textColor = AppColors.onErrorContainer;
          break;
        default:
          bgColor = AppColors.surfaceVariant;
          textColor = AppColors.onSurfaceVariant;
      }
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
