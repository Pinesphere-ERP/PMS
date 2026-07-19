import '../../../features/rooms/domain/models/room_entity.dart';

abstract class IRoomDao {
  int put(RoomEntity entity);
  List<RoomEntity> getAll();
  RoomEntity? get(int id);
  bool remove(int id);
  RoomEntity? findByUuid(String uuid);
}
