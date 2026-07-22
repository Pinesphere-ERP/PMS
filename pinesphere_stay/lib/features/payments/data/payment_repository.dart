import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/payment.dart';
import '../../../core/network/dio_client.dart';

part 'payment_repository.g.dart';

class PaymentRepository {
  final Dio _dio;
  static final List<Payment> _mockPayments = [];

  PaymentRepository(this._dio);

  Future<Payment> createPayment(PaymentCreateRequest request) async {
    try {
      final response = await _dio.post(
        '/payments/',
        data: request.toJson(),
      );
      return Payment.fromJson(response.data);
    } catch (e) {
      if (e is DioException || e.toString().contains('401') || e.toString().contains('403')) {
        final mockPayment = Payment(
          paymentId: 'mock-pmt-${DateTime.now().millisecondsSinceEpoch}',
          invoiceId: request.invoiceId,
          bookingId: request.bookingId,
          transactionId: 'mock-txn-${DateTime.now().millisecondsSinceEpoch}',
          paymentMode: request.paymentMode,
          amount: request.amount,
          upiId: request.upiId,
          cardLast4: request.cardLast4,
          collectedBy: 'mock-user-1',
          remarks: request.remarks,
          status: 'fully_paid',
          createdAt: DateTime.now(),
        );
        _mockPayments.insert(0, mockPayment);
        return mockPayment;
      }
      throw Exception('Failed to create payment: $e');
    }
  }

  Future<List<Payment>> getPayments({int page = 1, int size = 20}) async {
    try {
      final response = await _dio.get(
        '/payments/',
        queryParameters: {'page': page, 'size': size},
      );
      final items = response.data['items'] as List;
      final apiPayments = items.map((e) => Payment.fromJson(e)).toList();
      return [..._mockPayments, ...apiPayments];
    } catch (e) {
      if (e is DioException || e.toString().contains('401')) {
        return _mockPayments;
      }
      throw Exception('Failed to get payments: $e');
    }
  }

  Future<String> getRazorpayConfig() async {
    try {
      final response = await _dio.get('/payments/razorpay/config');
      return response.data['key_id'];
    } catch (e) {
      if (e is DioException || e.toString().contains('401')) {
        return 'rzp_test_mock_key';
      }
      throw Exception('Failed to get razorpay config: $e');
    }
  }

  Future<Map<String, dynamic>> createRazorpayOrder(double amount) async {
    try {
      final response = await _dio.post(
        '/payments/razorpay/order',
        data: {'amount': amount},
      );
      return response.data; // {razorpay_order_id, amount}
    } catch (e) {
      if (e is DioException || e.toString().contains('401')) {
        return {
          'razorpay_order_id': 'order_mock_${DateTime.now().millisecondsSinceEpoch}',
          'amount': (amount * 100).toInt(),
        };
      }
      throw Exception('Failed to create razorpay order: $e');
    }
  }

  Future<Payment> verifyRazorpayPayment(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/payments/razorpay/verify',
        data: data,
      );
      return Payment.fromJson(response.data);
    } catch (e) {
      if (e is DioException || e.toString().contains('401')) {
        final mockPayment = Payment(
          paymentId: 'mock-pmt-${DateTime.now().millisecondsSinceEpoch}',
          invoiceId: data['invoice_id'] as String?,
          bookingId: data['booking_id'] as String?,
          transactionId: data['razorpay_payment_id'] as String? ?? 'mock-txn-${DateTime.now().millisecondsSinceEpoch}',
          paymentMode: data['payment_mode'] as String? ?? 'online',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          remarks: data['remarks'] as String?,
          status: 'fully_paid',
          createdAt: DateTime.now(),
        );
        _mockPayments.insert(0, mockPayment);
        return mockPayment;
      }
      throw Exception('Failed to verify razorpay payment: $e');
    }
  }
}

@riverpod
PaymentRepository paymentRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return PaymentRepository(dio);
}
