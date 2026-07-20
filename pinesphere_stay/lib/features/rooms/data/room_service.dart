import '../../../main.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/database/dao/room_dao.dart';
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
  );
  return service;
}

class RoomService {
  // ignore: unused_field
  final Dio _dio;
  late final IRoomDao _roomDao;
  late final SyncService _syncService;

  RoomService({required Dio dio}) : _dio = dio;

  void initialize(IRoomDao roomDao, SyncService syncService) {
    _roomDao = roomDao;
    _syncService = syncService;
  }

  Future<List<RoomEntity>> getRooms(String propertyId) async {
    return _roomDao.getAll();
  }

  Future<List<RoomEntity>> getRoomGrid(String propertyId) async {
    return _roomDao.getAll();
  }

  Future<void> updateRoomStatus(String roomId, String occupancyStatus, String housekeepingStatus) async {
    final room = _roomDao.findByUuid(roomId);

    if (room != null) {
      final updatedRoom = RoomEntity(
        id: room.id,
        uuid: room.uuid,
        name: room.name,
        type: room.type,
        status: occupancyStatus,
        pricePerNight: room.pricePerNight,
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
      );
      _roomDao.put(updatedRoom);

      _syncService.enqueueMutation(
        entityType: 'Room',
        entityId: updatedRoom.id,
        operation: 'UPDATE',
        payload: {
          'id': roomId,
          'status': occupancyStatus,
          'housekeeping_status': housekeepingStatus,
        },
      );
    }
  }
}
