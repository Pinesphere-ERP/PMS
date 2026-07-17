import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/rooms/domain/models/roomentity.dart';
import 'room_dao.dart';

class RoomDaoNative implements IRoomDao {
  final Box<RoomEntity> _box;

  RoomDaoNative(this._box);

  @override
  int put(RoomEntity entity) {
    return _box.put(entity);
  }

  @override
  List<RoomEntity> getAll() {
    return _box.getAll();
  }

  @override
  RoomEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
