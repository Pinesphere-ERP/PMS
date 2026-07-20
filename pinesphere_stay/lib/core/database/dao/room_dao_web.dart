import '../../../features/rooms/domain/models/room_entity.dart';
import 'room_dao.dart';

class RoomDaoWeb implements IRoomDao {
  final Map<int, RoomEntity> _storage = {};
  int _counter = 1;

  @override
  int put(RoomEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<RoomEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  List<RoomEntity> findByProperty(String propertyId) {
    return _storage.values.where((e) => e.propertyId == propertyId).toList();
  }

  @override
  RoomEntity? get(int id) {
    return _storage[id];
  }

  @override
  bool remove(int id) {
    if (_storage.containsKey(id)) {
      _storage.remove(id);
      return true;
    }
    return false;
  }

  @override
  RoomEntity? getByServerId(String serverId) {
    for (final entity in _storage.values) {
      if (entity.serverId == serverId) return entity;
    }
    return null;
  }
}
