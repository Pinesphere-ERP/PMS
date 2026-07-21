import 'package:freezed_annotation/freezed_annotation.dart';

part 'property_wizard_model.freezed.dart';
part 'property_wizard_model.g.dart';

@freezed
abstract class PropertyWizardModel with _$PropertyWizardModel {
  const factory PropertyWizardModel({
    @Default('') String propertyId,
    @Default('') String name,
    @Default('HOTEL') String propertyType,
    @Default(3) int starCategory,
    @Default('') String address,
    @Default('') String city,
    @Default('') String state,
    @Default('') String country,
    @Default('') String zipCode,
    @Default(0.0) double latitude,
    @Default(0.0) double longitude,
    @Default(<String>[]) List<String> amenities,
    @Default(<String>[]) List<String> images,
    @Default('') String checkInTime,
    @Default('') String checkOutTime,
    @Default('') String cancellationPolicy,
    @Default('') String houseRules,
    @Default(0) int currentStep,
    @Default(false) bool isCompleted,
    @Default('draft') String status, // draft, pending_approval, approved
  }) = _PropertyWizardModel;

  factory PropertyWizardModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyWizardModelFromJson(json);
}
