import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/repository/manager_repository.dart';

import 'package:pinesphere_stay/features/manager/models/maintenance_model.dart';

final managerMaintenanceProvider = FutureProvider.autoDispose<List<MaintenanceTicket>>((ref) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getMaintenanceTickets();
  return data.map((e) => MaintenanceTicket.fromJson(e as Map<String, dynamic>)).toList();
});
