import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_metrics_model.freezed.dart';
part 'dashboard_metrics_model.g.dart';

@freezed
abstract class DashboardMetricsModel with _$DashboardMetricsModel {
  const factory DashboardMetricsModel({
    @JsonKey(name: 'todays_arrivals') @Default(0) int todaysArrivals,
    @JsonKey(name: 'todays_departures') @Default(0) int todaysDepartures,
    @JsonKey(name: 'occupied_rooms') @Default(0) int occupiedRooms,
    @JsonKey(name: 'vacant_rooms') @Default(0) int vacantRooms,
    @JsonKey(name: 'pending_checkouts') @Default(0) int pendingCheckouts,
    @JsonKey(name: 'housekeeping_count') @Default(0) int housekeepingCount,
    @JsonKey(name: 'pending_payments_count') @Default(0) int pendingPaymentsCount,
    @JsonKey(name: 'revenue_today') @Default(0.0) double revenueToday,
  }) = _DashboardMetricsModel;

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardMetricsModelFromJson(json);
}
