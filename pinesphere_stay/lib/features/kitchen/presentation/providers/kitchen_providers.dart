import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/tasks/data/models/task_model.dart';
import 'package:pinesphere_stay/features/kitchen/data/kitchen_service.dart';
import 'package:pinesphere_stay/features/rooms/presentation/providers/pms_provider.dart';

final kitchenTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final service = ref.watch(kitchenServiceProvider);
  final pms = ref.watch(pmsProvider);
  final propertyId = pms.selectedResortId;
  
  if (propertyId == null) return [];
  
  return service.getOrders(propertyId);
});

final kitchenTaskControllerProvider = Provider((ref) {
  return KitchenTaskController(ref);
});

class KitchenTaskController {
  final Ref _ref;
  KitchenTaskController(this._ref);

  Future<void> acceptOrder(String taskId) async {
    await _ref.read(kitchenServiceProvider).updateOrderStatus(taskId, 'accepted');
    _ref.invalidate(kitchenTasksProvider);
  }

  Future<void> startPreparing(String taskId) async {
    await _ref.read(kitchenServiceProvider).updateOrderStatus(taskId, 'in_progress');
    _ref.invalidate(kitchenTasksProvider);
  }

  Future<void> markReady(String taskId) async {
    await _ref.read(kitchenServiceProvider).updateOrderStatus(taskId, 'ready');
    _ref.invalidate(kitchenTasksProvider);
  }
  
  Future<void> markDelivered(String taskId) async {
    await _ref.read(kitchenServiceProvider).updateOrderStatus(taskId, 'completed');
    _ref.invalidate(kitchenTasksProvider);
  }
}
