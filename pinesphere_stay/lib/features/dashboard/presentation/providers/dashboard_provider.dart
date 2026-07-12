import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pinesphere_stay/features/rooms/presentation/providers/pms_provider.dart';
import 'package:flutter/material.dart';

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

  DashboardState copyWith({
    int? todaysArrivals,
    int? todaysDepartures,
    int? occupiedRooms,
    int? vacantRooms,
    int? pendingCheckouts,
    int? housekeepingCount,
    int? pendingPaymentsCount,
    double? revenueToday,
  }) {
    return DashboardState(
      todaysArrivals: todaysArrivals ?? this.todaysArrivals,
      todaysDepartures: todaysDepartures ?? this.todaysDepartures,
      occupiedRooms: occupiedRooms ?? this.occupiedRooms,
      vacantRooms: vacantRooms ?? this.vacantRooms,
      pendingCheckouts: pendingCheckouts ?? this.pendingCheckouts,
      housekeepingCount: housekeepingCount ?? this.housekeepingCount,
      pendingPaymentsCount: pendingPaymentsCount ?? this.pendingPaymentsCount,
      revenueToday: revenueToday ?? this.revenueToday,
    );
  }
}

@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  DashboardState build() {
    final pmsState = ref.watch(pmsProvider);
    final now = DateTime.now();

    int arrivals = 0;
    int departures = 0;
    int checkouts = 0;
    int pendingPayments = 0;
    double revenue = 0.0;

    for (var booking in pmsState.bookings) {
      if (DateUtils.isSameDay(booking.checkInDate, now)) {
        arrivals++;
      }
      if (DateUtils.isSameDay(booking.checkOutDate, now) || (booking.status == 'Active' && booking.checkOutDate.isBefore(now))) {
        departures++;
      }
      if (booking.status == 'Active' && (booking.checkOutDate.isBefore(now) || DateUtils.isSameDay(booking.checkOutDate, now))) {
        checkouts++;
      }
      if (!booking.isPaid && (booking.totalSum - booking.depositPaid) > 0) {
        pendingPayments++;
      }
      if (DateUtils.isSameDay(booking.checkInDate, now) || (booking.status == 'Active' && !booking.checkInDate.isAfter(now))) {
        // Just a simple approximation for today's revenue from active/arriving bookings
        revenue += booking.totalSum;
      }
    }

    int occupiedRooms = pmsState.rooms.where((r) => r.status.toLowerCase() == 'occupied').length;
    int vacantRooms = pmsState.rooms.where((r) => r.status.toLowerCase() == 'vacant').length;
    int housekeeping = pmsState.rooms.where((r) => r.status.toLowerCase() == 'cleaning' || r.status.toLowerCase() == 'maintenance').length;

    return DashboardState(
      todaysArrivals: arrivals,
      todaysDepartures: departures,
      occupiedRooms: occupiedRooms,
      vacantRooms: vacantRooms,
      pendingCheckouts: checkouts,
      housekeepingCount: housekeeping,
      pendingPaymentsCount: pendingPayments,
      revenueToday: revenue,
    );
  }
}
