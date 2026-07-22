import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/presentation/payment_history_screen.dart';
import '../../../payments/data/payment_repository.dart';
import '../../../payments/domain/models/payment.dart';

class IncomeDetailScreen extends ConsumerStatefulWidget {
  const IncomeDetailScreen({super.key});

  @override
  ConsumerState<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends ConsumerState<IncomeDetailScreen> {
  String _searchQuery = '';
  String _selectedMode = 'all';

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Income Transactions'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryCard(paymentsAsync),
          _buildFilters(),
          Expanded(child: _buildTransactionList(paymentsAsync)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AsyncValue<List<Payment>> paymentsAsync) {
    return paymentsAsync.maybeWhen(
      data: (payments) {
        final total = payments.fold(0.0, (sum, p) => sum + p.amount);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Income (This Property)',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${payments.length} successful transactions',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox(),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by Transaction/UPI ID...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
            ),
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Modes'),
                _buildFilterChip('cash', 'Cash'),
                _buildFilterChip('upi', 'UPI'),
                _buildFilterChip('card', 'Card'),
                _buildFilterChip('online', 'Online'),
              ],
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String mode, String label) {
    final isSelected = _selectedMode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (val) => setState(() => _selectedMode = mode),
        selectedColor: AppColors.secondaryContainer,
        checkmarkColor: AppColors.onSecondaryContainer,
      ),
    );
  }

  Widget _buildTransactionList(AsyncValue<List<Payment>> paymentsAsync) {
    return paymentsAsync.when(
      data: (payments) {
        final filtered = payments.where((p) {
          final modeLower = p.paymentMode.toLowerCase();
          final matchesSearch = p.transactionId.toLowerCase().contains(_searchQuery) ||
              (p.upiId?.toLowerCase().contains(_searchQuery) ?? false) ||
              (p.paymentId.toLowerCase().contains(_searchQuery));
          
          if (_selectedMode == 'all') return matchesSearch;
          if (_selectedMode == 'card') {
            return matchesSearch && (modeLower.contains('card') || modeLower.contains('credit') || modeLower.contains('debit'));
          }
          return matchesSearch && modeLower == _selectedMode;
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No transactions match the criteria.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final p = filtered[index];
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.paymentMode.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '₹${p.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Guest Name', 'John Doe'), // Mocked guest name
                    _buildDetailRow('Payment ID', p.paymentId),
                    _buildDetailRow('Transaction ID', p.transactionId),
                    if (p.upiId != null) _buildDetailRow('UPI ID', p.upiId!),
                    _buildDetailRow('Sent To', 'PineStay Admin Property'),
                    _buildDetailRow('Date', '${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year} ${p.createdAt.hour}:${p.createdAt.minute}'),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
