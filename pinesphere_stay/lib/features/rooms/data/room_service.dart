import '../../../main.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/database/dao/room_dao.dart';
import '../../audit/data/audit_service.dart';
import '../../sync/data/sync_service.dart';
import '../domain/models/room_entity.dart';

part 'room_service.g.dart';

@Riverpod(keepAlive: true)
RoomService roomService(Ref ref) {
  final service = RoomService(
    dio: ref.watch(dioClientProvider),
  );
  service.initialize(
    databaseService.roomDao,
    ref.read(syncServiceProvider),
    ref.read(auditServiceProvider),
  );
  return service;
}

class RoomService {
  // ignore: unused_field
  final Dio _dio;
  late final IRoomDao _roomDao;
  late final SyncService _syncService;
  late final AuditService _audit;

  RoomService({required Dio dio}) : _dio = dio;

  void initialize(IRoomDao roomDao, SyncService syncService, AuditService audit) {
    _roomDao = roomDao;
    _syncService = syncService;
    _audit = audit;
  }

  Future<List<RoomEntity>> getRooms(String propertyId) async {
    return _roomDao.findByProperty(propertyId);
  }

  Future<List<RoomEntity>> getRoomGrid(String propertyId) async {
    return _roomDao.findByProperty(propertyId);
  }

  Future<void> updateRoomStatus(String roomId, String occupancyStatus, String housekeepingStatus) async {
    final room = _roomDao.getByServerId(roomId);

    if (room != null) {
      final updatedRoom = RoomEntity(
        id: room.id,
        serverId: room.serverId,
        name: room.name,
        type: room.type,
        status: occupancyStatus,
        pricePerNight: room.pricePerNight,
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
        syncStatus: 'Pending',
      );
      _roomDao.put(updatedRoom);

      _syncService.enqueueMutation(
        entityType: 'Room',
        entityId: roomId,
        operation: 'UPDATE',
        payload: {
          'server_id': roomId,
          'status': occupancyStatus,
          'housekeeping_status': housekeepingStatus,
        },
      );

      _audit.log(
        moduleName: 'rooms',
        actionType: 'update_status',
        targetEntity: 'room',
        targetRecordId: roomId,
        propertyId: room.propertyId,
        newValue: {
          'status': occupancyStatus,
          'housekeeping_status': housekeepingStatus,
        },
      );
    }
  }
}
