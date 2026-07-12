import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/dio_client.dart';
import '../../../objectbox.g.dart';
import '../../sync/data/sync_service.dart';
import '../domain/models/room_entity.dart';

part 'room_service.g.dart';

@Riverpod(keepAlive: true)
RoomService roomService(Ref ref) {
  return RoomService(
    dio: ref.watch(dioClientProvider),
  );
}

class RoomService {
  final Dio _dio;
  late final Store _store;
  late final Box<RoomEntity> _roomBox;
  late final SyncService _syncService;

  RoomService({required this._dio});

  void initialize(Store store, SyncService syncService) {
    _store = store;
    _roomBox = _store.box<RoomEntity>();
    _syncService = syncService;
  }

  Future<List<RoomEntity>> getRooms(String propertyId) async {
    return _roomBox.getAll();
  }

  Future<List<RoomEntity>> getRoomGrid(String propertyId) async {
    return _roomBox.getAll();
  }

  Future<void> updateRoomStatus(String roomId, String occupancyStatus, String housekeepingStatus) async {
    final query = _roomBox.query(RoomEntity_.uuid.equals(roomId)).build();
    final rooms = query.find();
    query.close();

    if (rooms.isNotEmpty) {
      final room = rooms.first;
      final updatedRoom = RoomEntity(
        id: room.id,
        uuid: room.uuid,
        name: room.name,
        type: room.type,
        status: occupancyStatus,
        pricePerNight: room.pricePerNight,
        lastModifiedHlc: DateTime.now().toUtc().toIso8601String(),
      );
      _roomBox.put(updatedRoom);

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
