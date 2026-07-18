import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

class FolioScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const FolioScreen({super.key, required this.bookingId});

  @override
  ConsumerState<FolioScreen> createState() => _FolioScreenState();
}

class _FolioScreenState extends ConsumerState<FolioScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest Folio'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Print Folio
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () {
              // Add Custom Charge
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookingSummary(),
            const SizedBox(height: 24),
            _buildChargesList(),
            const SizedBox(height: 24),
            _buildPaymentsList(),
            const SizedBox(height: 24),
            _buildTotalSummary(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildBookingSummary() {
    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking: #${widget.bookingId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Guest: John Doe'),
            const Text('Room: 101 - Standard'),
            const Text('Dates: Oct 1 - Oct 5, 2023 (4 Nights)'),
          ],
        ),
      ),
    );
  }

  Widget _buildChargesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Charges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildLineItem('Room Charge (4 Nights)', '₹4,000.00'),
        _buildLineItem('Room Service - Dinner', '₹850.00'),
        _buildLineItem('Laundry Service', '₹200.00'),
        const Divider(),
        _buildLineItem('Subtotal', '₹5,050.00', isBold: true),
        _buildLineItem('CGST (9%)', '₹454.50'),
        _buildLineItem('SGST (9%)', '₹454.50'),
        const Divider(),
        _buildLineItem('Total Charges', '₹5,959.00', isBold: true, color: AppColors.error),
      ],
    );
  }

  Widget _buildPaymentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payments & Deposits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildLineItem('Advance Deposit (Card)', '-₹2,000.00', color: AppColors.primary),
        const Divider(),
        _buildLineItem('Total Payments', '-₹2,000.00', isBold: true, color: AppColors.primary),
      ],
    );
  }

  Widget _buildTotalSummary() {
    return Card(
      elevation: 0,
      color: AppColors.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildLineItem('Balance Due', '₹3,959.00', isBold: true, fontSize: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(String title, String amount, {bool isBold = false, Color? color, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
          Text(amount, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppColors.onSurface, fontSize: fontSize)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Route Charges'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Collect Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
