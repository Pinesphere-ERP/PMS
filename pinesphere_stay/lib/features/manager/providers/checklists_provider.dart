import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/manager/repository/manager_repository.dart';

import 'package:pinesphere_stay/features/manager/models/checklist_model.dart';

final managerChecklistsProvider = FutureProvider.autoDispose<List<DailyChecklist>>((ref) async {
  final repository = ref.watch(managerRepositoryProvider);
  final data = await repository.getChecklists();
  return data.map((e) => DailyChecklist.fromJson(e as Map<String, dynamic>)).toList();
});
