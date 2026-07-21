import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';
import 'package:pinesphere_stay/core/network/dio_client.dart';

part 'accountant_dashboard_provider.g.dart';

class AccountantDashboardState {
  final double accounting;
  final double income;
  final double expenses;
  final double profit;
  final double gst;
  final int invoices;
  final int reports;
  final List<dynamic> recentGuests;

  AccountantDashboardState({
    required this.accounting,
    required this.income,
    required this.expenses,
    required this.profit,
    required this.gst,
    required this.invoices,
    required this.reports,
    required this.recentGuests,
  });

  factory AccountantDashboardState.fromJson(Map<String, dynamic> json) {
    return AccountantDashboardState(
      accounting: (json['accounting'] ?? 0.0).toDouble(),
      income: (json['income'] ?? 0.0).toDouble(),
      expenses: (json['expenses'] ?? 0.0).toDouble(),
      profit: (json['profit'] ?? 0.0).toDouble(),
      gst: (json['gst'] ?? 0.0).toDouble(),
      invoices: json['invoices'] ?? 0,
      reports: json['reports'] ?? 0,
      recentGuests: json['recent_guests'] ?? [],
    );
  }
}

@riverpod
class AccountantDashboardNotifier extends _$AccountantDashboardNotifier {
  @override
  FutureOr<AccountantDashboardState> build() async {
    return _fetchDashboard();
  }

  Future<AccountantDashboardState> _fetchDashboard() async {
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/accountant/dashboard');
      return AccountantDashboardState.fromJson(response.data);
    } catch (e) {
      debugPrint('Failed to fetch accountant dashboard: $e');
      return AccountantDashboardState(
        accounting: 0.0,
        income: 0.0,
        expenses: 0.0,
        profit: 0.0,
        gst: 0.0,
        invoices: 0,
        reports: 0,
        recentGuests: [],
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDashboard());
  }
}
