import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/bento_card.dart';

class PendingPayment {
  final String roomNo;
  final String bookingId;
  final String guestName;
  final String mobileNumber;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalBillAmount;
  final double amountPaid;
  final double balanceDue;
  final String paymentStatus; // Pending, Partial
  final String paymentMethod;
  final DateTime dueDate;

  PendingPayment({
    required this.roomNo,
    required this.bookingId,
    required this.guestName,
    required this.mobileNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalBillAmount,
    required this.amountPaid,
    required this.balanceDue,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.dueDate,
  });
}

class PendingPaymentsScreen extends StatefulWidget {
  const PendingPaymentsScreen({super.key});

  @override
  State<PendingPaymentsScreen> createState() => _PendingPaymentsScreenState();
}

class _PendingPaymentsScreenState extends State<PendingPaymentsScreen> {
  final List<PendingPayment> _payments = [
    PendingPayment(
      roomNo: '101',
      bookingId: 'BK-202607-01',
      guestName: 'John Doe',
      mobileNumber: '+1 234 567 8900',
      checkInDate: DateTime.now().subtract(const Duration(days: 2)),
      checkOutDate: DateTime.now().add(const Duration(days: 1)),
      totalBillAmount: 500.0,
      amountPaid: 100.0,
      balanceDue: 400.0,
      paymentStatus: 'Partial',
      paymentMethod: 'Credit Card',
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ),
    PendingPayment(
      roomNo: 'Cottage 3',
      bookingId: 'BK-202607-05',
      guestName: 'Jane Smith',
      mobileNumber: '+44 7700 900077',
      checkInDate: DateTime.now().subtract(const Duration(days: 1)),
      checkOutDate: DateTime.now().add(const Duration(days: 3)),
      totalBillAmount: 1200.0,
      amountPaid: 0.0,
      balanceDue: 1200.0,
      paymentStatus: 'Pending',
      paymentMethod: 'Bank Transfer',
      dueDate: DateTime.now().add(const Duration(days: 3)),
    ),
    PendingPayment(
      roomNo: '205',
      bookingId: 'BK-202607-08',
      guestName: 'Robert Johnson',
      mobileNumber: '+91 98765 43210',
      checkInDate: DateTime.now().subtract(const Duration(days: 5)),
      checkOutDate: DateTime.now().subtract(const Duration(days: 1)), // Checkout past due
      totalBillAmount: 850.0,
      amountPaid: 400.0,
      balanceDue: 450.0,
      paymentStatus: 'Partial',
      paymentMethod: 'Cash',
      dueDate: DateTime.now().subtract(const Duration(days: 1)), // Overdue
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Pending Payments', style: TextStyle(color: AppColors.primary)),
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
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
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

  Widget _buildPaymentCard(PendingPayment payment) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final isOverdue = payment.dueDate.isBefore(DateTime.now());

    return BentoCard(
      onTap: () => _showPaymentDetails(payment, currencyFormatter),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.errorContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.error),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.guestName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Room: ${payment.roomNo} | ID: ${payment.bookingId}',
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
                currencyFormatter.format(payment.balanceDue),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusChip(payment.paymentStatus, isOverdue: isOverdue),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(PendingPayment payment, NumberFormat formatter) {
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
          initialChildSize: 0.65,
          maxChildSize: 0.9,
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
                          'Payment Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildStatusChip(payment.paymentStatus),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(Icons.person, 'Guest Name', payment.guestName),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.phone, 'Mobile Number', payment.mobileNumber),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.meeting_room, 'Room / Cottage', payment.roomNo),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.tag, 'Booking ID', payment.bookingId),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.login, 'Check-in Date', DateFormat('MMM d, y').format(payment.checkInDate)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.logout, 'Check-out Date', DateFormat('MMM d, y').format(payment.checkOutDate)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.event_busy, 'Due Date', DateFormat('MMM d, y').format(payment.dueDate)),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.monetization_on, 'Total Bill', formatter.format(payment.totalBillAmount)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.payment, 'Amount Paid', formatter.format(payment.amountPaid)),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.account_balance_wallet, 'Balance Due', formatter.format(payment.balanceDue), isAlert: true),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.credit_card, 'Payment Method', payment.paymentMethod),
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

  Widget _buildStatusChip(String status, {bool isOverdue = false}) {
    Color bgColor;
    Color textColor;
    String displayStatus = status;

    if (isOverdue) {
      bgColor = AppColors.errorContainer;
      textColor = AppColors.onErrorContainer;
      displayStatus = 'Overdue';
    } else {
      switch (status.toLowerCase()) {
        case 'pending':
          bgColor = AppColors.errorContainer;
          textColor = AppColors.onErrorContainer;
          break;
        case 'partial':
          bgColor = AppColors.secondaryContainer;
          textColor = AppColors.onSecondaryContainer;
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
        displayStatus,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
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
