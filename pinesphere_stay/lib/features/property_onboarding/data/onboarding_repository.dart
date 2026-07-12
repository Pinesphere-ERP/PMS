import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_repository.g.dart';

@riverpod
OnboardingRepository onboardingRepository(Ref ref) {
  return OnboardingRepository();
}

class OnboardingRepository {
  Future<void> submitOnboarding({
    required String ownerName,
    required String ownerEmail,
    required String businessName,
    required String propertyName,
    required String location,
  }) async {
    // Network latency simulation for property onboarding API
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
