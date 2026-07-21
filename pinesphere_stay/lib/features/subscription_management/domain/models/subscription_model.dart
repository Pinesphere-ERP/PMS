import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

@freezed
abstract class SubscriptionModel with _$SubscriptionModel {
  const factory SubscriptionModel({
    @Default('') String id,
    @Default('') String plan,
    @Default('') String status,
    @Default('') String billingCycle,
    @Default('') String startDate,
    @Default('') String expiryDate,
    @Default(0) int daysRemaining,
    @Default(0) int deviceLimit,
    @Default(0) int registeredDevices,
    @Default(false) bool subscriptionRequired,
    @Default(false) bool isTrial,
    @Default(false) bool isActive,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);
}

@freezed
abstract class SubscriptionPlanModel with _$SubscriptionPlanModel {
  const factory SubscriptionPlanModel({
    @Default('') String id,
    @Default('') String name,
    @Default('') String features,
    @Default('0') String amount,
    @Default(1) int duration,
    @Default('Active') String status,
  }) = _SubscriptionPlanModel;

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanModelFromJson(json);
}
