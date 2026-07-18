import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pinesphere_stay/features/tasks/data/models/task_model.dart';
import 'package:pinesphere_stay/features/tasks/presentation/providers/task_providers.dart';

final kitchenTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasksByType('food');
});

final kitchenTaskControllerProvider = Provider((ref) {
  return KitchenTaskController(ref);
});

class KitchenTaskController {
  final Ref _ref;
  KitchenTaskController(this._ref);

  void acceptOrder(String taskId) {
    _ref.read(taskRepositoryProvider).updateTaskStatus(taskId, 'accepted');
  }

  void startPreparing(String taskId) {
    _ref.read(taskRepositoryProvider).updateTaskStatus(taskId, 'in_progress');
  }

  void markReady(String taskId) {
    _ref.read(taskRepositoryProvider).updateTaskStatus(taskId, 'ready');
  }
  
  void markDelivered(String taskId) {
    _ref.read(taskRepositoryProvider).updateTaskStatus(taskId, 'completed');
  }
}
