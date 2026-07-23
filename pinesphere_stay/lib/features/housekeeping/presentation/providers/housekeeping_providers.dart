import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/housekeeping/data/housekeeping_service.dart';
import 'package:pinesphere_stay/features/housekeeping/domain/models/housekeeping_task_entity.dart';
import 'package:pinesphere_stay/features/rooms/presentation/providers/pms_provider.dart';
import '../../../../main.dart';
import '../../../sync/data/sync_service.dart';
import 'package:uuid/uuid.dart';

final housekeepingTasksProvider = FutureProvider<List<HousekeepingTaskEntity>>((ref) async {
  final service = ref.watch(housekeepingServiceProvider);
  final pms = ref.watch(pmsProvider);
  final propertyId = pms.selectedResortId;
  
  if (propertyId == null) return [];
  
  // 1. Generate missing tasks for dirty rooms locally first
  final housekeepingRoomDao = databaseService.housekeepingRoomStatusDao;
  final housekeepingDao = databaseService.housekeepingDao;
  
  final dirtyRooms = housekeepingRoomDao.getByPropertyId(propertyId).where((r) => r.cleanStatus != 'clean').toList();
  for (final room in dirtyRooms) {
    final existingTasks = housekeepingDao.queryTasks(propertyId);
    final hasActiveTask = existingTasks.any((t) => t.roomId == room.serverId && t.status != 'completed' && t.status != 'closed');
    
    if (!hasActiveTask) {
      final newTaskId = const Uuid().v4();
      final newTask = HousekeepingTaskEntity(
        serverId: newTaskId,
        roomId: room.serverId,
        propertyId: propertyId,
        roomNumber: room.roomNumber,
        status: 'pending',
        priority: 'medium',
        remarks: 'Auto-generated for dirty room',
        createdAt: DateTime.now().toUtc().toIso8601String(),
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
      );
      housekeepingDao.put(newTask);
      
      // Enqueue sync so backend knows
      ref.read(syncServiceProvider).enqueueMutation(
        entityType: 'HousekeepingTask',
        entityId: newTaskId,
        operation: 'CREATE',
        payload: {
          'uuid': newTaskId,
          'room_id': room.serverId,
          'property_id': propertyId,
          'room_number': room.roomNumber,
          'status': 'pending',
          'priority': 'medium',
          'remarks': 'Auto-generated for dirty room',
        },
      );
    }
  }

  // 2. Fetch tasks (local DB or API)
  final rawData = await service.getTasks(propertyId);
  final tasks = rawData.map((body) => HousekeepingTaskEntity(
        serverId: body['id']?.toString() ?? '',
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
      )).toList().cast<HousekeepingTaskEntity>();
      
  // Also merge any local-only tasks that haven't synced yet
  final localTasks = housekeepingDao.queryTasks(propertyId);
  final serverTaskIds = tasks.map((t) => t.serverId).toSet();
  for (final localTask in localTasks) {
    if (!serverTaskIds.contains(localTask.serverId)) {
      tasks.add(localTask);
    }
  }
  
  return tasks;
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

  Future<void> markCompleted(String taskId, {String? photoPath, String? roomId, String? propertyId}) async {
    final updateData = <String, dynamic>{'status': 'completed'};
    if (photoPath != null) {
      updateData['after_photo'] = photoPath;
    }
    await _ref.read(housekeepingServiceProvider).updateTask(taskId, updateData);
    
    // Auto-update room status to clean
    if (roomId != null && propertyId != null) {
      // Assuming 'Available' is default, or just leave occupancy status unchanged
      final roomDao = databaseService.roomDao;
      final room = roomDao.getByServerId(roomId);
      if (room != null) {
        room.lastModifiedHlc = DateTime.now().toUtc().toIso8601String();
        room.syncStatus = 'Pending';
        roomDao.put(room);
        
        _ref.read(syncServiceProvider).enqueueMutation(
          entityType: 'Room',
          entityId: roomId,
          operation: 'UPDATE',
          payload: {
            'server_id': roomId,
            'housekeeping_status': 'clean',
          },
        );
      }
      
      final housekeepingRoom = databaseService.housekeepingRoomStatusDao.getByRoomId(roomId);
      if (housekeepingRoom != null) {
        housekeepingRoom.cleanStatus = 'clean';
        databaseService.housekeepingRoomStatusDao.put(housekeepingRoom);
      }
    }
    
    _ref.invalidate(housekeepingTasksProvider);
  }
}
