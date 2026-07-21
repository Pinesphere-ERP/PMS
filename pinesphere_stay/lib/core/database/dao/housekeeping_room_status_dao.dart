import '../../../features/housekeeping/domain/models/housekeeping_room_status_entity.dart';

abstract class IHousekeepingRoomStatusDao {
  void put(HousekeepingRoomStatusEntity entity);
  void putMany(List<HousekeepingRoomStatusEntity> entities);
  List<HousekeepingRoomStatusEntity> getByPropertyId(String propertyId);
  HousekeepingRoomStatusEntity? getByRoomId(String roomId);
  void deleteAll();
}
