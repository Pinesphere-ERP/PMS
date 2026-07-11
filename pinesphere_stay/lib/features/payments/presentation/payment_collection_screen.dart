import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/security/permission_engine.dart';
import '../../../../core/presentation/widgets/access_restricted_view.dart';
import 'package:pinesphere_stay/features/auth/presentation/providers/auth_notifier.dart';
import '../data/payment_repository.dart';
import '../domain/models/payment.dart';

class PaymentCollectionScreen extends ConsumerStatefulWidget {
  const PaymentCollectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentCollectionScreen> createState() => _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends ConsumerState<PaymentCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedMode = 'cash';
  bool _isLoading = false;
  late Razorpay _razorpay;

  // Split payments state
  final List<SplitPayment> _splits = [];
  
  // Single payment fields
  final _upiController = TextEditingController();
  final _cardLast4Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    _remarksController.dispose();
    _upiController.dispose();
    _cardLast4Controller.dispose();
    super.dispose();
  }

  void _addSplit() {
    String splitMode = 'cash';
    final splitAmountCtrl = TextEditingController();
    
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Add Split Payment'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: splitMode,
                  items: const [
                    DropdownMenuItem(value: 'online', child: Text('Online (Razorpay)')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI (Manual)')),
                    DropdownMenuItem(value: 'credit_card', child: Text('Credit Card (Manual)')),
                    DropdownMenuItem(value: 'debit_card', child: Text('Debit Card (Manual)')),
                  ],
                  onChanged: (v) => setDialogState(() => splitMode = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: splitAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (₹)'),
                )
              ],
            );
          }
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(splitAmountCtrl.text) ?? 0.0;
              if (amt > 0) {
                setState(() {
                  _splits.add(SplitPayment(mode: splitMode, amount: amt));
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          )
        ],
      );
    });
  }

  double get _totalSplitAmount => _splits.fold(0.0, (sum, item) => sum + item.amount);

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final amount = double.parse(_amountController.text);
      final repo = ref.read(paymentRepositoryProvider);
      
      final Map<String, dynamic> verifyPayload = {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'amount': amount,
        'remarks': _remarksController.text.isNotEmpty ? _remarksController.text : null,
        'payment_mode': _selectedMode,
      };

      if (_selectedMode == 'split') {
        verifyPayload['split_payments'] = _splits.map((s) => s.toJson()).toList();
      }

      await repo.verifyRazorpayPayment(verifyPayload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successfully recorded!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isLoading = false);
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authState = ref.read(authProvider);
    final user = authState.maybeWhen(authenticated: (u) => u, orElse: () => null);
    final isGuest = user?.role == UserRole.guest;
    final effectiveMode = isGuest ? 'online' : _selectedMode;

    final amount = double.parse(_amountController.text);

    if (effectiveMode == 'split') {
      if (_splits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one split payment')));
        return;
      }
      if ((_totalSplitAmount - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Split amounts must equal total amount')));
        return;
      }
    }

    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(paymentRepositoryProvider);

      bool requiresRazorpay = effectiveMode == 'online';
      double razorpayAmount = amount;

      if (effectiveMode == 'split') {
        final onlineSplits = _splits.where((s) => s.mode == 'online').toList();
        if (onlineSplits.isNotEmpty) {
          requiresRazorpay = true;
          razorpayAmount = onlineSplits.fold(0.0, (sum, s) => sum + s.amount);
        }
      }

      if (requiresRazorpay) {
        final keyId = await repo.getRazorpayConfig();
        final order = await repo.createRazorpayOrder(razorpayAmount);
        
        var options = {
          'key': keyId,
          'amount': order['amount'],
          'name': 'Pinesphere Stay',
          'order_id': order['razorpay_order_id'],
          'description': 'Payment Collection',
          'timeout': 300, 
        };
        _razorpay.open(options);
      } else {
        final request = PaymentCreateRequest(
          paymentMode: effectiveMode,
          amount: amount,
          upiId: effectiveMode == 'upi' ? _upiController.text : null,
          cardLast4: ['credit_card', 'debit_card'].contains(effectiveMode) ? _cardLast4Controller.text : null,
          remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
          splitPayments: effectiveMode == 'split' ? _splits : null,
        );

        await repo.createPayment(request);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successfully recorded!')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.maybeWhen(
      authenticated: (u) => u,
      orElse: () => null,
    );
    final role = user?.role ?? UserRole.guest;

    final canView = PermissionEngine.hasPermission(role, PermissionModule.payments, PermissionAction.view);
    final canCollect = PermissionEngine.hasPermission(role, PermissionModule.payments, PermissionAction.collect);
    final canPayOnline = PermissionEngine.hasPermission(role, PermissionModule.payments, PermissionAction.payOnline);

    if (!canView && !canCollect && !canPayOnline) {
      return const Scaffold(
        body: AccessRestrictedView(
          title: 'Payments Restricted',
          message: 'Your role does not permit access to the Payments module.',
        ),
      );
    }

    final isViewOnly = !canCollect && !canPayOnline;
    final isGuest = role == UserRole.guest;
    final effectiveMode = isGuest ? 'online' : _selectedMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Collect Payment')),
      body: Column(
        children: [
          if (isViewOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.amber.withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'View-Only Mode',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: AbsorbPointer(
                absorbing: isViewOnly,
                child: Form(
                  key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Total Amount (₹)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => (val == null || double.tryParse(val) == null) ? 'Enter valid amount' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: effectiveMode,
                decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: 'online', child: Text('Online (Razorpay)')),
                  if (!isGuest) ...[
                    const DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    const DropdownMenuItem(value: 'upi', child: Text('UPI (Manual)')),
                    const DropdownMenuItem(value: 'credit_card', child: Text('Credit Card (Manual)')),
                    const DropdownMenuItem(value: 'debit_card', child: Text('Debit Card (Manual)')),
                    const DropdownMenuItem(value: 'split', child: Text('Split Payment')),
                  ],
                ],
                onChanged: isGuest
                    ? null
                    : (val) {
                        if (val != null) setState(() => _selectedMode = val);
                      },
              ),
              if (effectiveMode == 'upi') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _upiController,
                  decoration: const InputDecoration(labelText: 'UPI Reference ID', border: OutlineInputBorder()),
                  validator: (val) => effectiveMode == 'upi' && (val == null || val.isEmpty) ? 'Enter UPI Reference ID' : null,
                ),
              ],
              if (['credit_card', 'debit_card'].contains(effectiveMode)) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardLast4Controller,
                  decoration: const InputDecoration(labelText: 'Card Last 4 Digits', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (val) => ['credit_card', 'debit_card'].contains(effectiveMode) && (val == null || val.length != 4) ? 'Enter last 4 digits' : null,
                ),
              ],
              if (effectiveMode == 'split') ...[
                const SizedBox(height: 16),
                const Text('Split Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ..._splits.asMap().entries.map((e) {
                  return ListTile(
                    title: Text(e.value.mode.toUpperCase()),
                    trailing: Text('₹${e.value.amount.toStringAsFixed(2)}'),
                    leading: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _splits.removeAt(e.key)),
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: _addSplit,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Split'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Split: ₹${_totalSplitAmount.toStringAsFixed(2)} / ₹${_amountController.text.isEmpty ? "0.00" : _amountController.text}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: (double.tryParse(_amountController.text) ?? 0.0) == _totalSplitAmount 
                        ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks (Optional)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              if (!isViewOnly) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Text('Record Payment', style: TextStyle(fontSize: 18)),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    ),
  ],
),
    );
  }
}
