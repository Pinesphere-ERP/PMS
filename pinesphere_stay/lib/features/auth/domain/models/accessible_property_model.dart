import 'package:freezed_annotation/freezed_annotation.dart';

part 'accessible_property_model.freezed.dart';
part 'accessible_property_model.g.dart';

@freezed
abstract class AccessiblePropertyModel with _$AccessiblePropertyModel {
  const factory AccessiblePropertyModel({
    @JsonKey(name: 'property_id') required String propertyId,
    @JsonKey(name: 'property_name') String? propertyName,
    @JsonKey(name: 'onboarding_status') String? onboardingStatus,
    @JsonKey(name: 'subscription_status') String? subscriptionStatus,
    @JsonKey(name: 'trial_ends_at') String? trialEndsAt,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
  }) = _AccessiblePropertyModel;

  factory AccessiblePropertyModel.fromJson(Map<String, dynamic> json) =>
      _$AccessiblePropertyModelFromJson(json);
}
