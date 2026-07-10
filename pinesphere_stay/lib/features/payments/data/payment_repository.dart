import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/payment.dart';
import '../../../core/network/dio_client.dart';

part 'payment_repository.g.dart';

class PaymentRepository {
  final Dio _dio;

  PaymentRepository(this._dio);

  Future<Payment> createPayment(PaymentCreateRequest request) async {
    try {
      final response = await _dio.post(
        '/payments/',
        data: request.toJson(),
      );
      return Payment.fromJson(response.data);
    } catch (e) {
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
      return items.map((e) => Payment.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get payments: $e');
    }
  }

  Future<String> getRazorpayConfig() async {
    try {
      final response = await _dio.get('/payments/razorpay/config');
      return response.data['key_id'];
    } catch (e) {
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
      throw Exception('Failed to verify razorpay payment: $e');
    }
  }
}

@riverpod
PaymentRepository paymentRepository(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return PaymentRepository(dio);
}
