import '../../../main.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/database/dao/housekeeping_dao.dart';
import '../../../core/database/dao/maintenance_dao.dart';
import '../../audit/data/audit_service.dart';
import '../../sync/data/sync_service.dart';
import '../domain/models/housekeeping_task_entity.dart';
import '../domain/models/maintenance_ticket_entity.dart';

part 'housekeeping_service.g.dart';

@Riverpod(keepAlive: true)
HousekeepingService housekeepingService(Ref ref) {
  final service = HousekeepingService(
    dio: ref.watch(dioClientProvider),
  );
  service.initialize(databaseService.housekeepingDao, databaseService.maintenanceDao, ref.read(syncServiceProvider), ref.read(auditServiceProvider));
  return service;
}

class HousekeepingService {
  final Dio _dio;
  late final IHousekeepingDao _housekeepingDao;
  late final IMaintenanceDao _maintenanceDao;
  late final SyncService _syncService;
  late final AuditService _audit;

  HousekeepingService({required this._dio});

  void initialize(IHousekeepingDao housekeepingDao, IMaintenanceDao maintenanceDao, SyncService syncService, AuditService audit) {
    _housekeepingDao = housekeepingDao;
    _maintenanceDao = maintenanceDao;
    _syncService = syncService;
    _audit = audit;
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/housekeeping/tasks', data: data);
      final body = response.data as Map<String, dynamic>;
      final entity = HousekeepingTaskEntity(
        serverId: body['id']?.toString() ?? data['uuid'] ?? '',
        roomId: body['room_id']?.toString() ?? data['room_id'] ?? '',
        propertyId: body['property_id']?.toString() ?? data['property_id'] ?? '',
        roomNumber: body['room_number']?.toString() ?? data['room_number'] ?? '',
        assignedStaffId: body['assigned_staff_id']?.toString() ?? data['assigned_staff_id'] ?? '',
        assignedStaffName: body['assigned_staff_name']?.toString() ?? data['assigned_staff_name'] ?? '',
        status: body['status']?.toString() ?? 'pending',
        priority: body['priority']?.toString() ?? 'medium',
        checklistStatus: body['checklist_status']?.toString() ?? '',
        remarks: body['remarks']?.toString() ?? data['remarks'] ?? '',
        beforePhoto: body['before_photo']?.toString() ?? data['before_photo'] ?? '',
        afterPhoto: body['after_photo']?.toString() ?? data['after_photo'] ?? '',
        completedAt: body['completed_at']?.toString() ?? '',
        inspectedBy: body['inspected_by']?.toString() ?? '',
        inspectionResult: body['inspection_result']?.toString() ?? '',
        inspectionRemarks: body['inspection_remarks']?.toString() ?? '',
        inspectedAt: body['inspected_at']?.toString() ?? '',
        createdAt: body['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        lastModifiedHlc: body['last_modified_hlc']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      );
      _housekeepingDao.put(entity);
      return body;
    } on DioException catch (e) {
      AppLogger.w('createTask network failed, storing locally and queuing sync', e);
      final localUuid = data['uuid'] ?? const Uuid().v4();
      final _ = HousekeepingTaskEntity(
        serverId: localUuid.toString(),
        roomId: data['room_id'] ?? '',
        propertyId: data['property_id'] ?? '',
        roomNumber: data['room_number'] ?? '',
        assignedStaffId: data['assigned_staff_id'] ?? '',
        assignedStaffName: data['assigned_staff_name'] ?? '',
        status: 'pending',
        priority: data['priority'] ?? 'medium',
        remarks: data['remarks'] ?? '',
        beforePhoto: data['before_photo'] ?? '',
        afterPhoto: data['after_photo'] ?? '',
        createdAt: DateTime.now().toUtc().toIso8601String(),
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
      );
      _housekeepingDao.put(entity);

      _syncService.enqueueMutation(
        entityType: 'HousekeepingTask',
        entityId: localUuid.toString(),
        operation: 'CREATE',
        payload: {...data, 'uuid': localUuid.toString()},
      );
      
      _audit.log(
        moduleName: 'housekeeping',
        actionType: 'create_task',
        targetEntity: 'housekeeping_task',
        targetRecordId: localUuid.toString(),
        propertyId: data['property_id'],
        newValue: data,
      );
      
      return data;
    } catch (e) {
      AppLogger.e('createTask unexpected error', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getTasks(String propertyId, {String? status, String? staffId}) async {
    try {
      final queryParams = <String, dynamic>{'property_id': propertyId};
      if (status != null) queryParams['status'] = status;
      if (staffId != null) queryParams['staff_id'] = staffId;
      final response = await _dio.get('/housekeeping/tasks', queryParameters: queryParams);
      final List<dynamic> dataList = response.data as List<dynamic>;
      
      final entities = dataList.map<HousekeepingTaskEntity>((body) => HousekeepingTaskEntity(
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
      )).toList();
      
      if (entities.isNotEmpty) {
        _housekeepingDao.putMany(entities);
      }
      
      return dataList;
    } on DioException catch (e) {
      AppLogger.w('getTasks network failed, falling back to ObjectBox', e);
      return _housekeepingDao.queryTasks(propertyId, status: status, staffId: staffId);
    } catch (e) {
      AppLogger.e('getTasks unexpected error', e);
      return _housekeepingDao.queryTasks(propertyId, status: status, staffId: staffId);
    }
  }

  Future<Map<String, dynamic>> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/housekeeping/tasks/$taskId', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.w('updateTask network failed, queuing sync', e);
      _syncService.enqueueMutation(
        entityType: 'HousekeepingTask',
        entityId: taskId,
        operation: 'UPDATE',
        payload: {'id': taskId, ...data},
      );
      
      _audit.log(
        moduleName: 'housekeeping',
        actionType: 'update_task',
        targetEntity: 'housekeeping_task',
        targetRecordId: taskId,
        propertyId: data['property_id'],
        newValue: data,
      );
      
      return data;
    } catch (e) {
      AppLogger.e('updateTask unexpected error', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> inspectTask(String taskId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/housekeeping/tasks/$taskId/inspect', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.w('inspectTask network failed, queuing sync', e);
      _syncService.enqueueMutation(
        entityType: 'HousekeepingTask',
        entityId: taskId,
        operation: 'UPDATE',
        payload: {'id': taskId, ...data, 'action': 'inspect'},
      );
      
      _audit.log(
        moduleName: 'housekeeping',
        actionType: 'inspect_task',
        targetEntity: 'housekeeping_task',
        targetRecordId: taskId,
        propertyId: data['property_id'],
        newValue: data,
      );
      
      return data;
    } catch (e) {
      AppLogger.e('inspectTask unexpected error', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMaintenanceTicket(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/housekeeping/maintenance', data: data);
      final body = response.data as Map<String, dynamic>;
      final entity = MaintenanceTicketEntity(
        serverId: body['id']?.toString() ?? data['uuid'] ?? '',
        roomId: body['room_id']?.toString() ?? data['room_id'] ?? '',
        propertyId: body['property_id']?.toString() ?? data['property_id'] ?? '',
        roomNumber: body['room_number']?.toString() ?? data['room_number'] ?? '',
        reportedBy: body['reported_by']?.toString() ?? data['reported_by'] ?? '',
        reportedByName: body['reported_by_name']?.toString() ?? data['reported_by_name'] ?? '',
        assignedTo: body['assigned_to']?.toString() ?? data['assigned_to'] ?? '',
        assignedToName: body['assigned_to_name']?.toString() ?? data['assigned_to_name'] ?? '',
        category: body['category']?.toString() ?? data['category'] ?? '',
        priority: body['priority']?.toString() ?? 'medium',
        issueDescription: body['issue_description']?.toString() ?? data['issue_description'] ?? '',
        status: body['status']?.toString() ?? 'open',
        repairCost: double.tryParse(body['repair_cost']?.toString() ?? '') ?? data['repair_cost'] ?? 0,
        createdAt: body['created_at']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        resolvedAt: body['resolved_at']?.toString() ?? '',
        photoUrl: body['photo_url']?.toString() ?? data['photo_url'] ?? '',
        lastModifiedHlc: body['last_modified_hlc']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      );
      _maintenanceDao.put(entity);
      return body;
    } on DioException catch (e) {
      AppLogger.w('createMaintenanceTicket network failed, storing locally and queuing sync', e);
      final localUuid = data['uuid'] ?? const Uuid().v4();
      final _ = MaintenanceTicketEntity(
        serverId: localUuid.toString(),
        roomId: data['room_id'] ?? '',
        propertyId: data['property_id'] ?? '',
        roomNumber: data['room_number'] ?? '',
        reportedBy: data['reported_by'] ?? '',
        reportedByName: data['reported_by_name'] ?? '',
        assignedTo: data['assigned_to'] ?? '',
        assignedToName: data['assigned_to_name'] ?? '',
        category: data['category'] ?? '',
        priority: data['priority'] ?? 'medium',
        issueDescription: data['issue_description'] ?? '',
        status: 'open',
        repairCost: (data['repair_cost'] ?? 0).toDouble(),
        createdAt: DateTime.now().toUtc().toIso8601String(),
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
      );
      _maintenanceDao.put(entity);

      _syncService.enqueueMutation(
        entityType: 'MaintenanceTicket',
        entityId: localUuid.toString(),
        operation: 'CREATE',
        payload: {...data, 'uuid': localUuid.toString()},
      );
      
      _audit.log(
        moduleName: 'maintenance',
        actionType: 'create_ticket',
        targetEntity: 'maintenance_ticket',
        targetRecordId: localUuid.toString(),
        propertyId: data['property_id'],
        newValue: data,
      );
      
      return data;
    } catch (e) {
      AppLogger.e('createMaintenanceTicket unexpected error', e);
      rethrow;
    }
  }

  Future<List<dynamic>> getMaintenanceTickets(String propertyId, {String? status, String? category}) async {
    try {
      final queryParams = <String, dynamic>{'property_id': propertyId};
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      final response = await _dio.get('/housekeeping/maintenance', queryParameters: queryParams);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      AppLogger.w('getMaintenanceTickets network failed, falling back to ObjectBox', e);
      return _maintenanceDao.queryTickets(propertyId, status: status, category: category);
    } catch (e) {
      AppLogger.e('getMaintenanceTickets unexpected error', e);
      return _maintenanceDao.queryTickets(propertyId, status: status, category: category);
    }
  }

  Future<Map<String, dynamic>> updateMaintenanceTicket(String ticketId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/housekeeping/maintenance/$ticketId', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.w('updateMaintenanceTicket network failed, queuing sync', e);
      _syncService.enqueueMutation(
        entityType: 'MaintenanceTicket',
        entityId: ticketId,
        operation: 'UPDATE',
        payload: {'id': ticketId, ...data},
      );
      
      _audit.log(
        moduleName: 'maintenance',
        actionType: 'update_ticket',
        targetEntity: 'maintenance_ticket',
        targetRecordId: ticketId,
        propertyId: data['property_id'],
        newValue: data,
      );
      
      return data;
    } catch (e) {
      AppLogger.e('updateMaintenanceTicket unexpected error', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDashboard(String propertyId) async {
    try {
      final response = await _dio.get('/housekeeping/dashboard', queryParameters: {'property_id': propertyId});
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.e('getDashboard network failed', e);
      rethrow;
    } catch (e) {
      AppLogger.e('getDashboard unexpected error', e);
      rethrow;
    }
  }
}
