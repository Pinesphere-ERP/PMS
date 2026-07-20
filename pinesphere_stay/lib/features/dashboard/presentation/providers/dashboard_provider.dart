import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';
import 'package:pinesphere_stay/core/network/dio_client.dart';
import 'package:pinesphere_stay/features/rooms/presentation/providers/pms_provider.dart';

part 'dashboard_provider.g.dart';

class DashboardState {
  final int todaysArrivals;
  final int todaysDepartures;
  final int occupiedRooms;
  final int vacantRooms;
  final int pendingCheckouts;
  final int housekeepingCount;
  final int pendingPaymentsCount;
  final double revenueToday;

  DashboardState({
    required this.todaysArrivals,
    required this.todaysDepartures,
    required this.occupiedRooms,
    required this.vacantRooms,
    required this.pendingCheckouts,
    required this.housekeepingCount,
    required this.pendingPaymentsCount,
    required this.revenueToday,
  });

  factory DashboardState.fromJson(Map<String, dynamic> json) {
    return DashboardState(
      todaysArrivals: json['todays_arrivals'] ?? 0,
      todaysDepartures: json['todays_departures'] ?? 0,
      occupiedRooms: json['occupied_rooms'] ?? 0,
      vacantRooms: json['vacant_rooms'] ?? 0,
      pendingCheckouts: json['pending_checkouts'] ?? 0,
      housekeepingCount: json['housekeeping_count'] ?? 0,
      pendingPaymentsCount: json['pending_payments_count'] ?? 0,
      revenueToday: (json['revenue_today'] ?? 0.0).toDouble(),
    );
  }
}

@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  FutureOr<DashboardState> build() async {
    return _fetchDashboard();
  }

  Future<DashboardState> _fetchDashboard() async {
    try {
      final dio = ref.read(dioClientProvider);
      final pmsState = ref.read(pmsProvider);
      
      final Map<String, dynamic> queryParams = {};
      if (pmsState.selectedResortId != null) {
        queryParams['property_id'] = pmsState.selectedResortId;
      }
      
      final response = await dio.get('/dashboard', queryParameters: queryParams);
      return DashboardState.fromJson(response.data);
    } catch (e) {
      debugPrint('Failed to fetch dashboard metrics: $e');
      // Return zeroes on error
      return DashboardState(
        todaysArrivals: 0,
        todaysDepartures: 0,
        occupiedRooms: 0,
        vacantRooms: 0,
        pendingCheckouts: 0,
        housekeepingCount: 0,
        pendingPaymentsCount: 0,
        revenueToday: 0.0,
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDashboard());
  }
}
