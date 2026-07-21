import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/models/dashboard_model.dart';
import 'package:pinesphere_stay/features/manager/repository/manager_repository.dart';

final managerDashboardProvider = FutureProvider.autoDispose<ManagerDashboardResponse>((ref) async {
  final repository = ref.watch(managerRepositoryProvider);
  return await repository.getDashboard();
});
