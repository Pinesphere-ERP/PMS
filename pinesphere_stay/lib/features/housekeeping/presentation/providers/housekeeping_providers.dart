import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/housekeeping/data/housekeeping_service.dart';
import 'package:pinesphere_stay/features/housekeeping/domain/models/housekeeping_task_entity.dart';
import 'package:pinesphere_stay/features/rooms/presentation/providers/pms_provider.dart';

final housekeepingTasksProvider = FutureProvider<List<HousekeepingTaskEntity>>((ref) async {
  final service = ref.watch(housekeepingServiceProvider);
  final pms = ref.watch(pmsProvider);
  final propertyId = pms.selectedResortId;
  
  if (propertyId == null) return [];
  
  // getTasks returns List<dynamic>, so we need to fetch it from the database instead
  // since the fallback already upserted it. Let's just call getTasks then query DB.
  // Actually, getTasks returns raw json. The generic way the DAO works is better.
  // Let's use the dao directly to stream it, or just use getTasks and map it.
  final rawData = await service.getTasks(propertyId);
  return rawData.map((body) => HousekeepingTaskEntity(
        uuid: body['id']?.toString() ?? '',
        roomId: body['room_id']?.toString() ?? '',
        propertyId: body['property_id']?.toString() ?? '',
        roomNumber: body['room_number']?.toString() ?? '',
        assignedStaffId: body['assigned_staff_id']?.toString() ?? '',
        assignedStaffName: body['assigned_staff_name']?.toString() ?? '',
        status: body['status']?.toString() ?? 'pending',
        priority: body['priority']?.toString() ?? 'medium',
        checklistStatus: body['checklist_status']?.toString() ?? '',
        remarks: body['remarks']?.toString() ?? '',
        beforePhoto: body['before_photo']?.toString() ?? '',
        afterPhoto: body['after_photo']?.toString() ?? '',
        completedAt: body['completed_at']?.toString() ?? '',
        inspectedBy: body['inspected_by']?.toString() ?? '',
        inspectionResult: body['inspection_result']?.toString() ?? '',
        inspectionRemarks: body['inspection_remarks']?.toString() ?? '',
        inspectedAt: body['inspected_at']?.toString() ?? '',
        createdAt: body['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        lastModifiedHlc: body['last_modified_hlc']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      )).toList();
});

final housekeepingTaskControllerProvider = Provider((ref) {
  return HousekeepingTaskController(ref);
});

class HousekeepingTaskController {
  final Ref _ref;
  HousekeepingTaskController(this._ref);

  Future<void> acceptTask(String taskId) async {
    await _ref.read(housekeepingServiceProvider).updateTask(taskId, {'status': 'accepted'});
    _ref.invalidate(housekeepingTasksProvider);
  }

  Future<void> startCleaning(String taskId) async {
    await _ref.read(housekeepingServiceProvider).updateTask(taskId, {'status': 'in_progress'});
    _ref.invalidate(housekeepingTasksProvider);
  }

  Future<void> markCompleted(String taskId) async {
    await _ref.read(housekeepingServiceProvider).updateTask(taskId, {'status': 'completed'});
    _ref.invalidate(housekeepingTasksProvider);
  }
}
