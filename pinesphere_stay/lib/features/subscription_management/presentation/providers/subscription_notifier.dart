import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/subscription_model.dart';
import '../../data/repositories/subscription_repository.dart';

part 'subscription_notifier.g.dart';

@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  Future<SubscriptionModel?> build() async {
    return _fetchSubscription();
  }

  Future<SubscriptionModel?> _fetchSubscription() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    return repo.getMySubscription();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSubscription());
  }

  Future<String?> upgradePlan(String planName) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    return repo.createCheckoutSession(planName);
  }

  Future<bool> cancelSubscription() async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final success = await repo.cancelSubscription();
    if (success) {
      await reload();
    }
    return success;
  }
}

@riverpod
Future<List<SubscriptionPlanModel>> subscriptionPlans(Ref ref) async {
  final repo = ref.read(subscriptionRepositoryProvider);
  return repo.getPlans();
}
