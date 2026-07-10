import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
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
  final _upiController = TextEditingController();
  final _cardLast4Controller = TextEditingController();
  final _remarksController = TextEditingController();

  String _selectedMode = 'cash';
  bool _isLoading = false;
  late Razorpay _razorpay;

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
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final repo = ref.read(paymentRepositoryProvider);
      await repo.verifyRazorpayPayment({
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
        'amount': double.parse(_amountController.text),
        'remarks': _remarksController.text.isNotEmpty ? _remarksController.text : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Online Payment successfully recorded!')),
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final amount = double.parse(_amountController.text);
      final repo = ref.read(paymentRepositoryProvider);

      if (_selectedMode == 'online') {
        // Razorpay flow
        final keyId = await repo.getRazorpayConfig();
        final order = await repo.createRazorpayOrder(amount);
        
        var options = {
          'key': keyId,
          'amount': order['amount'],
          'name': 'Pinesphere Stay',
          'order_id': order['razorpay_order_id'],
          'description': 'Payment Collection',
          'timeout': 300, 
        };
        _razorpay.open(options);
        // Note: _isLoading remains true until Razorpay callbacks fire
      } else {
        // Offline / Manual mode flow
        final request = PaymentCreateRequest(
          paymentMode: _selectedMode,
          amount: amount,
          upiId: _selectedMode == 'upi' ? _upiController.text : null,
          cardLast4: ['credit_card', 'debit_card'].contains(_selectedMode) ? _cardLast4Controller.text : null,
          remarks: _remarksController.text.isNotEmpty ? _remarksController.text : null,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collect Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  if (double.tryParse(value) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'online', child: Text('Online (Razorpay)')),
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI (Manual)')),
                  DropdownMenuItem(value: 'credit_card', child: Text('Credit Card (Manual)')),
                  DropdownMenuItem(value: 'debit_card', child: Text('Debit Card (Manual)')),
                  DropdownMenuItem(value: 'net_banking', child: Text('Net Banking (Manual)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMode = val);
                },
              ),
              if (_selectedMode == 'upi') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _upiController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Enter UPI ID' : null,
                ),
              ],
              if (['credit_card', 'debit_card'].contains(_selectedMode)) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardLast4Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card Last 4 Digits',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter last 4 digits';
                    if (val.length != 4) return 'Must be 4 digits';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text('Record Payment', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
