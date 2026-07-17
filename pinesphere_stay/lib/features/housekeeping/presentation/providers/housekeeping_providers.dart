import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/tasks/data/models/task_model.dart';
import 'package:pinesphere_stay/features/tasks/presentation/providers/task_providers.dart';


final housekeepingTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasksByType('cleaning');
});

final housekeepingTaskControllerProvider = Provider((ref) {
  return HousekeepingTaskController(ref);
});

class HousekeepingTaskController {
  final Ref _ref;
  HousekeepingTaskController(this._ref);

  void acceptTask(String taskId) {
    _ref.read(taskRepositoryProvider).updateTaskStatus(taskId, 'accepted');
  }

  void startCleaning(String taskId) {
    _ref.read(taskRepositoryProvider).updateTaskStatus(taskId, 'in_progress');
  }

  void markCompleted(String taskId) {
    _ref.read(taskRepositoryProvider).updateTaskStatus(taskId, 'completed');
  }
}
