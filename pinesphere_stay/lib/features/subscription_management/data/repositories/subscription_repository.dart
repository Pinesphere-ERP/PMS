import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/core/network/dio_client.dart';
import '../../domain/models/subscription_model.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(dioClientProvider));
});

class SubscriptionRepository {
  final Dio _dio;

  SubscriptionRepository(this._dio);

  Future<SubscriptionModel?> getMySubscription() async {
    try {
      final response = await _dio.get('/subscriptions/my-subscription');
      if (response.data['data'] != null) {
        return SubscriptionModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<SubscriptionPlanModel>> getPlans() async {
    try {
      final response = await _dio.get('/subscriptions/plans');
      final data = response.data['data'] as List;
      return data.map((e) => SubscriptionPlanModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> createCheckoutSession(String planName) async {
    try {
      final response = await _dio.post('/subscriptions/create-checkout-session', data: {
        'plan': planName,
        'success_url': 'https://pinesphere.com/success',
        'cancel_url': 'https://pinesphere.com/cancel',
      });
      return response.data['checkout_url'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final response = await _dio.post('/subscriptions/cancel');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
