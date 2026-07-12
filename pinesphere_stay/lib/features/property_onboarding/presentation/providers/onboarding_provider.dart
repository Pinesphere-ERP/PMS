import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/onboarding_repository.dart';

part 'onboarding_provider.g.dart';

class OnboardingFormState {
  final String ownerName;
  final String ownerEmail;
  final String businessName;
  final String propertyName;
  final String location;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  OnboardingFormState({
    this.ownerName = '',
    this.ownerEmail = '',
    this.businessName = '',
    this.propertyName = '',
    this.location = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  OnboardingFormState copyWith({
    String? ownerName,
    String? ownerEmail,
    String? businessName,
    String? propertyName,
    String? location,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return OnboardingFormState(
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      businessName: businessName ?? this.businessName,
      propertyName: propertyName ?? this.propertyName,
      location: location ?? this.location,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingFormState build() => OnboardingFormState();

  void updateOwnerName(String name) => state = state.copyWith(ownerName: name);
  void updateOwnerEmail(String email) => state = state.copyWith(ownerEmail: email);
  void updateBusinessName(String name) => state = state.copyWith(businessName: name);
  void updatePropertyName(String name) => state = state.copyWith(propertyName: name);
  void updateLocation(String loc) => state = state.copyWith(location: loc);

  bool validateStep(int step) {
    // Basic validation rules per step (e.g. step 0 is owner registration, step 1 is business info)
    switch (step) {
      case 0:
        return state.ownerName.isNotEmpty && state.ownerEmail.contains('@');
      case 1:
        return state.businessName.isNotEmpty;
      case 2:
        return state.propertyName.isNotEmpty;
      case 3:
        return state.location.isNotEmpty;
      default:
        return true; 
    }
  }

  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null, isSuccess: false);
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      await repository.submitOnboarding(
        ownerName: state.ownerName,
        ownerEmail: state.ownerEmail,
        businessName: state.businessName,
        propertyName: state.propertyName,
        location: state.location,
      );
      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}
