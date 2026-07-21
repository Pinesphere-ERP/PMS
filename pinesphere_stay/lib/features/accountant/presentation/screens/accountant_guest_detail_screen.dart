import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/services/invoice_service.dart';

class AccountantGuestDetailScreen extends ConsumerWidget {
  final String bookingId;

  const AccountantGuestDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, you would fetch guest/booking details using this bookingId
    // For now, we mock the details
    final guestName = 'John Doe';
    final roomNumber = '101';
    final totalAmount = 5000.0;
    final paidAmount = 2500.0;
    final payments = [
      {'date': '2023-10-25', 'mode': 'UPI', 'transaction_id': 'TXN12345', 'amount': 1500.0},
      {'date': '2023-10-26', 'mode': 'Credit Card', 'transaction_id': 'TXN12346', 'amount': 1000.0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Guest Details - $guestName'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Guest Information'),
            _buildInfoRow('Guest Name', guestName),
            _buildInfoRow('Room Number', roomNumber),
            _buildInfoRow('Booking ID', bookingId),
            const SizedBox(height: 24),
            
            _buildSectionHeader('Financials'),
            _buildInfoRow('Total Amount', '\$${totalAmount.toStringAsFixed(2)}'),
            _buildInfoRow('Paid Amount', '\$${paidAmount.toStringAsFixed(2)}'),
            _buildInfoRow('Balance Due', '\$${(totalAmount - paidAmount).toStringAsFixed(2)}', isBold: true),
            const SizedBox(height: 24),

            _buildSectionHeader('Payment History'),
            ...payments.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                title: Text('${p['mode']} - ${p['transaction_id']}'),
                subtitle: Text('Date: ${p['date']}'),
                trailing: Text('\$${p['amount']}'),
              ),
            )),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Audit Logs'),
            const Card(
              child: ListTile(
                leading: Icon(Icons.history),
                title: Text('Booking Created'),
                subtitle: Text('2023-10-24 10:00 AM by Reception'),
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Generate Invoice'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimaryContainer,
                    ),
                    onPressed: () {
                      InvoiceService.generateAndDownloadInvoice(
                        guestName: guestName,
                        roomNumber: roomNumber,
                        totalAmount: totalAmount,
                        paidAmount: paidAmount,
                        payments: payments,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Collect Payment'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed: () {
                      // Navigate to standard payment collection screen
                      // Passing the required arguments via extras or router state
                      context.push('/payment-collection');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.error : AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
