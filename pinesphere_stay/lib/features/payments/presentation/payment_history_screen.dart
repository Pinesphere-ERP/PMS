import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/payment_repository.dart';
import '../domain/models/payment.dart';

part 'payment_history_screen.g.dart';

@riverpod
Future<List<Payment>> paymentsList(Ref ref) {
  return ref.watch(paymentRepositoryProvider).getPayments();
}

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(paymentsListProvider),
          )
        ],
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No payments found.'));
          }
          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(_getIconForMode(payment.paymentMode)),
                ),
                title: Text('₹${payment.amount.toStringAsFixed(2)} - ${payment.paymentMode.toUpperCase()}'),
                subtitle: Text('Status: ${payment.status} | TXN: ${payment.transactionId}'),
                trailing: Text(
                  '${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/payment-collection'),
        icon: const Icon(Icons.add),
        label: const Text('Collect Payment'),
      ),
    );
  }

  IconData _getIconForMode(String mode) {
    switch (mode) {
      case 'cash':
        return Icons.money;
      case 'upi':
        return Icons.phone_android;
      case 'credit_card':
      case 'debit_card':
        return Icons.credit_card;
      case 'net_banking':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }
}
