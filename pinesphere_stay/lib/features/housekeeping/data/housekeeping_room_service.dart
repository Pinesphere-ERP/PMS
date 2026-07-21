import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../../main.dart'; // To access databaseService
import '../domain/models/housekeeping_room_status_model.dart';
import '../domain/models/housekeeping_room_status_entity.dart';
import '../../sync/data/sync_service.dart';
import '../../audit/data/audit_service.dart';

part 'housekeeping_room_service.g.dart';

@riverpod
HousekeepingRoomService housekeepingRoomService(Ref ref) {
  final service = HousekeepingRoomService(dio: ref.watch(dioClientProvider));
  service.initialize(ref.read(syncServiceProvider), ref.read(auditServiceProvider));
  return service;
}

class HousekeepingRoomService {
  final Dio _dio;
  late final SyncService _syncService;
  late final AuditService _audit;

  // ignore: prefer_initializing_formals
  HousekeepingRoomService({required Dio dio}) : _dio = dio;

  void initialize(SyncService syncService, AuditService audit) {
    _syncService = syncService;
    _audit = audit;
  }

  Future<List<HousekeepingRoomStatusModel>> getRooms() async {
    try {
      final response = await _dio.get('/housekeeping/rooms');
      final data = (response.data as List).map((e) => HousekeepingRoomStatusModel.fromJson(e)).toList();
      
      // Upsert to local DB
      final dao = databaseService.housekeepingRoomStatusDao;
      final entities = data.map((model) => HousekeepingRoomStatusEntity.fromJson(model.toJson())).toList();
      if (entities.isNotEmpty) {
        dao.putMany(entities);
      }
      return data;
    } on DioException catch (e) {
      AppLogger.w('getRooms network failed, falling back to ObjectBox', e);
      // We don't have propertyId here easily without auth provider, but assuming dao gets all for now
      // Or we can get from authProvider, but for fallback we just read all in DAO
      // In a real app we'd pass propertyId or filter by it.
      return []; // Real fallback would read from DAO, handled in provider
    }
  }

  Future<HousekeepingRoomStatusModel> getRoomDetail(String roomId) async {
    final response = await _dio.get('/housekeeping/rooms/$roomId');
    return HousekeepingRoomStatusModel.fromJson(response.data);
  }

  Future<HousekeepingRoomStatusModel> completeCleaning(String roomId, List<String> imageUrls, String propertyId) async {
    try {
      final response = await _dio.post('/housekeeping/rooms/$roomId/complete', data: {'image_urls': imageUrls});
      final data = HousekeepingRoomStatusModel.fromJson(response.data);
      // Update local DB
      databaseService.housekeepingRoomStatusDao.put(HousekeepingRoomStatusEntity.fromJson(data.toJson()));
      return data;
    } on DioException catch (e) {
      AppLogger.w('completeCleaning network failed, queuing sync', e);
      _syncService.enqueueMutation(
        entityType: 'HousekeepingRoomStatus',
        entityId: roomId,
        operation: 'UPDATE',
        payload: {'action': 'complete_cleaning', 'room_id': roomId, 'image_urls': imageUrls},
      );
      _audit.log(
        moduleName: 'housekeeping',
        actionType: 'complete_cleaning_offline',
        targetEntity: 'housekeeping_room_status',
        targetRecordId: roomId,
        propertyId: propertyId,
        newValue: {'image_urls': imageUrls},
      );
      // Return optimistic model
      return HousekeepingRoomStatusModel(id: '', propertyId: propertyId, roomId: roomId, roomNumber: '', cleanStatus: 'clean');
    }
  }

  Future<HousekeepingRoomStatusModel> scheduleCleaning(String roomId, DateTime estimatedTime, String propertyId) async {
    try {
      final response = await _dio.post(
        '/housekeeping/rooms/$roomId/schedule',
        data: {'estimated_cleaning_time': estimatedTime.toUtc().toIso8601String()},
      );
      final data = HousekeepingRoomStatusModel.fromJson(response.data);
      databaseService.housekeepingRoomStatusDao.put(HousekeepingRoomStatusEntity.fromJson(data.toJson()));
      return data;
    } on DioException catch (e) {
      AppLogger.w('scheduleCleaning network failed, queuing sync', e);
      _syncService.enqueueMutation(
        entityType: 'HousekeepingRoomStatus',
        entityId: roomId,
        operation: 'UPDATE',
        payload: {'action': 'schedule_cleaning', 'room_id': roomId, 'estimated_cleaning_time': estimatedTime.toUtc().toIso8601String()},
      );
      return HousekeepingRoomStatusModel(id: '', propertyId: propertyId, roomId: roomId, roomNumber: '', cleanStatus: 'scheduled');
    }
  }

  Future<HousekeepingRoomStatusModel> updateStatus(String roomId, String status, String propertyId) async {
    try {
      final response = await _dio.patch(
        '/housekeeping/rooms/$roomId/status',
        data: {'clean_status': status},
      );
      final data = HousekeepingRoomStatusModel.fromJson(response.data);
      databaseService.housekeepingRoomStatusDao.put(HousekeepingRoomStatusEntity.fromJson(data.toJson()));
      return data;
    } on DioException catch (e) {
      AppLogger.w('updateStatus network failed, queuing sync', e);
      _syncService.enqueueMutation(
        entityType: 'HousekeepingRoomStatus',
        entityId: roomId,
        operation: 'UPDATE',
        payload: {'action': 'update_status', 'room_id': roomId, 'clean_status': status},
      );
      return HousekeepingRoomStatusModel(id: '', propertyId: propertyId, roomId: roomId, roomNumber: '', cleanStatus: status);
    }
  }
}
