import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/repository/manager_repository.dart';

import 'package:pinesphere_stay/features/manager/models/housekeeping_model.dart';

final managerHousekeepingProvider = FutureProvider.autoDispose<List<HousekeepingTask>>((ref) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getHousekeepingProgress();
  return data.map((e) => HousekeepingTask.fromJson(e as Map<String, dynamic>)).toList();
});
