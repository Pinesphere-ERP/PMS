import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/permissions/user_role.dart';
import 'accessible_property_model.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    required String name,
    required String email,
    required UserRole role,
    // The primary property this user is associated with
    @JsonKey(name: 'property_id') String? propertyId,
    // Role code string from backend (e.g. "OWNER", "RECEPTIONIST")
    @JsonKey(name: 'role_code') String? roleCode,
    // Mobile number
    @JsonKey(name: 'mobile_number') String? mobileNumber,
    // Onboarding status of the primary property
    @JsonKey(name: 'onboarding_status') String? onboardingStatus,
    // Subscription status of the primary property
    @JsonKey(name: 'subscription_status') String? subscriptionStatus,
    // Trial expiry date (ISO8601 string)
    @JsonKey(name: 'trial_ends_at') String? trialEndsAt,
    // All properties accessible by this user
    @JsonKey(name: 'accessible_properties')
    @Default([])
    List<AccessiblePropertyModel> accessibleProperties,
    // Whether the user's email is verified
    @JsonKey(name: 'is_email_verified') @Default(false) bool isEmailVerified,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
