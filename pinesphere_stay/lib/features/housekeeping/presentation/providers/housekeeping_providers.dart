import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/features/housekeeping/data/housekeeping_service.dart';
import 'package:pinesphere_stay/features/housekeeping/domain/models/housekeeping_task_entity.dart';
import 'package:pinesphere_stay/features/rooms/presentation/providers/pms_provider.dart';
import '../../../../main.dart';
import '../../../sync/data/sync_service.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

final housekeepingTasksProvider = FutureProvider.autoDispose<List<HousekeepingTaskEntity>>((ref) async {
  final service = ref.watch(housekeepingServiceProvider);
  final pms = ref.watch(pmsProvider);
  String? propertyId = pms.selectedResortId;
  
  if (propertyId == null) {
    final authState = ref.watch(authProvider);
    propertyId = authState.maybeWhen(
      authenticated: (user) => user.propertyId,
      orElse: () => null,
    );
  }

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
  final tasks = rawData.map((body) {
    // Encode checklist_status as JSON string for ObjectBox
    String checklistJson = '';
    final rawChecklist = body['checklist_status'];
    if (rawChecklist is Map) {
      try {
        checklistJson = jsonEncode(rawChecklist);
      } catch (_) {}
    }
    return HousekeepingTaskEntity(
      serverId: body['task_id']?.toString() ?? body['id']?.toString() ?? '',
      roomId: body['room_id']?.toString() ?? '',
      propertyId: body['property_id']?.toString() ?? '',
      roomNumber: body['room_number']?.toString() ?? '',
      assignedStaffId: body['assigned_staff_id']?.toString() ?? '',
      assignedStaffName: body['assigned_staff_name']?.toString() ?? '',
      status: body['status']?.toString() ?? 'pending',
      priority: body['priority']?.toString() ?? 'medium',
      checklistStatus: checklistJson,
      remarks: body['remarks']?.toString() ?? '',
      completionNotes: body['completion_notes']?.toString() ?? '',
      beforePhoto: body['before_photo']?.toString() ?? '',
      afterPhoto: body['after_photo']?.toString() ?? '',
      completedAt: body['completed_at']?.toString() ?? '',
      inspectedBy: body['inspected_by']?.toString() ?? '',
      inspectionResult: body['inspection_result']?.toString() ?? '',
      inspectionRemarks: body['inspection_remarks']?.toString() ?? '',
      inspectedAt: body['inspected_at']?.toString() ?? '',
      checkoutTime: body['checkout_time']?.toString() ?? '',
      guestName: body['guest_name']?.toString() ?? '',
      createdAt: body['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      lastModifiedHlc: body['last_modified_hlc']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
    );
  }).toList().cast<HousekeepingTaskEntity>();

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

  /// Move task from pending → in_progress using dedicated /start endpoint
  Future<void> startCleaning(String taskId) async {
    await _ref.read(housekeepingServiceProvider).startCleaning(taskId, {});
    _ref.invalidate(housekeepingTasksProvider);
  }

  /// Complete a task using dedicated /complete endpoint — validates checklist + photos
  Future<void> markCompleted(
    String taskId, {
    String? photoPath,
    String? roomId,
    String? propertyId,
    Map<String, dynamic>? checklistStatus,
    String? completionNotes,
  }) async {
    final updateData = <String, dynamic>{
      if (checklistStatus != null) 'checklist_status': checklistStatus,
      if (photoPath != null) 'after_photo': photoPath,
      if (completionNotes != null) 'completion_notes': completionNotes,
    };
    await _ref.read(housekeepingServiceProvider).completeCleaning(taskId, updateData);

    // Auto-update room status to clean in local DB
    if (roomId != null && propertyId != null) {
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

  /// Report damage during or after cleaning
  Future<void> reportDamage(
    String taskId,
    Map<String, dynamic> damageData,
  ) async {
    await _ref.read(housekeepingServiceProvider).reportDamage(taskId, damageData);
    _ref.invalidate(housekeepingTasksProvider);
  }
}
