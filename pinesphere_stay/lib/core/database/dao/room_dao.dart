import '../../../features/rooms/domain/models/roomentity.dart';

abstract class IRoomDao {
  int put(RoomEntity entity);
  List<RoomEntity> getAll();
  RoomEntity? get(int id);
  bool remove(int id);
}
