import '../../../features/housekeeping/domain/models/housekeeping_room_status_entity.dart';
import 'housekeeping_room_status_dao.dart';

class HousekeepingRoomStatusDaoWeb implements IHousekeepingRoomStatusDao {
  final Map<int, HousekeepingRoomStatusEntity> _storage = {};
  int _counter = 1;

  @override
  void put(HousekeepingRoomStatusEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
  }

  @override
  void putMany(List<HousekeepingRoomStatusEntity> entities) {
    for (var entity in entities) {
      put(entity);
    }
  }

  @override
  List<HousekeepingRoomStatusEntity> getByPropertyId(String propertyId) {
    return _storage.values.where((e) => e.propertyId == propertyId).toList();
  }

  @override
  HousekeepingRoomStatusEntity? getByRoomId(String roomId) {
    try {
      return _storage.values.firstWhere((e) => e.roomId == roomId);
    } catch (e) {
      return null;
    }
  }

  @override
  void deleteAll() {
    _storage.clear();
  }
}
