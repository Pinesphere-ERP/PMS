import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/services/invoice_service.dart';

class GSTInvoiceScreen extends ConsumerStatefulWidget {
  const GSTInvoiceScreen({super.key});

  @override
  ConsumerState<GSTInvoiceScreen> createState() => _GSTInvoiceScreenState();
}

class _GSTInvoiceScreenState extends ConsumerState<GSTInvoiceScreen> {
  final List<Map<String, dynamic>> _mockInvoices = [
    {
      'id': 'INV-2026-001',
      'guest_name': 'John Doe',
      'room_number': '101',
      'total_amount': 5000.0,
      'paid_amount': 5000.0,
      'date': '2026-07-20',
      'payments': [
        {'date': '2026-07-20', 'mode': 'UPI', 'transaction_id': 'TXN100021', 'amount': 5000.0}
      ]
    },
    {
      'id': 'INV-2026-002',
      'guest_name': 'Jane Smith',
      'room_number': '102',
      'total_amount': 7500.0,
      'paid_amount': 4000.0,
      'date': '2026-07-21',
      'payments': [
        {'date': '2026-07-21', 'mode': 'Cash', 'transaction_id': 'TXN100022', 'amount': 4000.0}
      ]
    },
    {
      'id': 'INV-2026-003',
      'guest_name': 'Robert Johnson',
      'room_number': '204',
      'total_amount': 12000.0,
      'paid_amount': 12000.0,
      'date': '2026-07-22',
      'payments': [
        {'date': '2026-07-22', 'mode': 'Credit Card', 'transaction_id': 'TXN100023', 'amount': 12000.0}
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate simple GST breakdown (assume 18% GST included in total amounts)
    double totalRevenue = _mockInvoices.fold(0.0, (sum, inv) => sum + inv['paid_amount']);
    double netTaxableAmount = totalRevenue / 1.18;
    double totalGST = totalRevenue - netTaxableAmount;
    double cgst = totalGST / 2;
    double sgst = totalGST / 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('GST & Invoices'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGSTBreakdownCard(totalRevenue, netTaxableAmount, cgst, sgst),
            const SizedBox(height: 24),
            Text(
              'Issued Invoices',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mockInvoices.length,
              itemBuilder: (context, index) {
                final inv = _mockInvoices[index];
                final balance = inv['total_amount'] - inv['paid_amount'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inv['id'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              inv['date'],
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Guest: ${inv['guest_name']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                Text('Room: ${inv['room_number']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Total: ₹${inv['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  balance > 0 ? 'Due: ₹$balance' : 'Fully Paid',
                                  style: TextStyle(
                                    color: balance > 0 ? Colors.red : Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              InvoiceService.generateAndDownloadInvoice(
                                guestName: inv['guest_name'],
                                roomNumber: inv['room_number'],
                                totalAmount: inv['total_amount'],
                                paidAmount: inv['paid_amount'],
                                payments: inv['payments'],
                              );
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Download Invoice PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGSTBreakdownCard(double total, double net, double cgst, double sgst) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GST Summary Breakdown (18%)',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Calculated based on actual collected invoice amounts.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(height: 32),
            _buildTaxRow('Gross Taxable Revenue', '₹${total.toStringAsFixed(2)}', isBold: true),
            const SizedBox(height: 8),
            _buildTaxRow('Net Taxable Amount', '₹${net.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildTaxRow('CGST (9%)', '₹${cgst.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildTaxRow('SGST (9%)', '₹${sgst.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildTaxRow('Total GST Collected', '₹${(cgst + sgst).toStringAsFixed(2)}', isBold: true, color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
