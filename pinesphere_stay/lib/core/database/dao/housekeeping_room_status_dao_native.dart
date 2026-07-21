import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/housekeeping/domain/models/housekeeping_room_status_entity.dart';
import 'housekeeping_room_status_dao.dart';

class HousekeepingRoomStatusDaoNative implements IHousekeepingRoomStatusDao {
  final Box<HousekeepingRoomStatusEntity> _box;

  HousekeepingRoomStatusDaoNative(this._box);

  @override
  void put(HousekeepingRoomStatusEntity entity) {
    _box.put(entity);
  }

  @override
  void putMany(List<HousekeepingRoomStatusEntity> entities) {
    _box.putMany(entities);
  }

  @override
  List<HousekeepingRoomStatusEntity> getByPropertyId(String propertyId) {
    final query = _box.query(HousekeepingRoomStatusEntity_.propertyId.equals(propertyId)).build();
    final results = query.find();
    query.close();
    return results;
  }

  @override
  HousekeepingRoomStatusEntity? getByRoomId(String roomId) {
    final query = _box.query(HousekeepingRoomStatusEntity_.roomId.equals(roomId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  @override
  void deleteAll() {
    _box.removeAll();
  }
}
