import '../../../features/rooms/domain/models/room_entity.dart';

abstract class IRoomDao {
  int put(RoomEntity entity);
  List<RoomEntity> getAll();
  List<RoomEntity> findByProperty(String propertyId);
  RoomEntity? get(int id);
  bool remove(int id);
  RoomEntity? getByServerId(String serverId);
}
