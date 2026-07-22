import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:pinesphere_stay/core/network/dio_client.dart';
import '../../domain/models/property_wizard_model.dart';
import 'package:dio/dio.dart';
part 'property_wizard_notifier.g.dart';

@riverpod
class PropertyWizardNotifier extends _$PropertyWizardNotifier {
  @override
  PropertyWizardModel build() {
    return const PropertyWizardModel();
  }

  void updateBasicInfo({
    String? name,
    String? propertyType,
    int? starCategory,
  }) {
    state = state.copyWith(
      name: name ?? state.name,
      propertyType: propertyType ?? state.propertyType,
      starCategory: starCategory ?? state.starCategory,
    );
  }

  void updateLocation({
    String? address,
    String? city,
    String? stateLoc,
    String? country,
    String? zipCode,
    double? latitude,
    double? longitude,
  }) {
    state = state.copyWith(
      address: address ?? state.address,
      city: city ?? state.city,
      state: stateLoc ?? state.state,
      country: country ?? state.country,
      zipCode: zipCode ?? state.zipCode,
      latitude: latitude ?? state.latitude,
      longitude: longitude ?? state.longitude,
    );
  }

  void updateAmenities(List<String> amenities) {
    state = state.copyWith(amenities: amenities);
  }

  void updateImages(List<String> images) {
    state = state.copyWith(images: images);
  }

  void updatePolicies({
    String? checkInTime,
    String? checkOutTime,
    String? cancellationPolicy,
    String? houseRules,
  }) {
    state = state.copyWith(
      checkInTime: checkInTime ?? state.checkInTime,
      checkOutTime: checkOutTime ?? state.checkOutTime,
      cancellationPolicy: cancellationPolicy ?? state.cancellationPolicy,
      houseRules: houseRules ?? state.houseRules,
    );
  }

  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void jumpToStep(int step) {
    if (step >= 0 && step <= 5) {
      state = state.copyWith(currentStep: step);
    }
  }

  Future<void> saveDraft(String propertyId) async {
    final dio = ref.read(dioClientProvider);
    try {
      await dio.patch('/properties/$propertyId/wizard-step', data: state.toJson());
    } catch (e) {
      // Ignore for now, offline sync will handle it later if integrated
    }
  }

  Future<bool> completeOnboarding(String propertyId) async {
    final dio = ref.read(dioClientProvider);
    try {
      state = state.copyWith(status: 'payment_pending');
      final response = await dio.post('/properties/$propertyId/complete-onboarding', data: state.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(isCompleted: true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("API Error in completeOnboarding: $e");
      if (e is DioException) {
        debugPrint("Response data: ${e.response?.data}");
        debugPrint("Response status: ${e.response?.statusCode}");
      }
      return false;
    }
  }
}
