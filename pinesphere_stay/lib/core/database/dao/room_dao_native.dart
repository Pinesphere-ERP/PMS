import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/rooms/domain/models/room_entity.dart';
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
  List<RoomEntity> findByProperty(String propertyId) {
    final query = _box.query(RoomEntity_.propertyId.equals(propertyId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  @override
  RoomEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }

  @override
  RoomEntity? getByServerId(String serverId) {
    final query = _box.query(RoomEntity_.serverId.equals(serverId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }
}
