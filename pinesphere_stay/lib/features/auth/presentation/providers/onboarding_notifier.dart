import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pinesphere_stay/features/auth/data/repositories/onboarding_repository.dart';

part 'onboarding_notifier.freezed.dart';
part 'onboarding_notifier.g.dart';

@freezed
sealed class OnboardingState with _$OnboardingState {
  const factory OnboardingState.initial() = _Initial;
  const factory OnboardingState.loading() = _Loading;
  const factory OnboardingState.success() = _Success;
  const factory OnboardingState.error(String message) = _Error;
}

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() {
    return const OnboardingState.initial();
  }

  Future<void> registerOwner({
    required String ownerName,
    required String email,
    required String mobileNumber,
    required String password,
    required String businessName,
    required String propertyName,
  }) async {
    state = const OnboardingState.loading();

    final result = await ref.read(onboardingRepositoryProvider).registerOwner(
      ownerName: ownerName,
      email: email,
      mobileNumber: mobileNumber,
      password: password,
      businessName: businessName,
      propertyName: propertyName,
    );

    result.fold(
      (failure) => state = OnboardingState.error(failure.message),
      (_) => state = const OnboardingState.success(),
    );
  }
}
