import '../../../features/checkin/domain/models/checkin_entity.dart';

abstract class ICheckinDao {
  int put(CheckInEntity entity);
  List<CheckInEntity> getAll();
  CheckInEntity? get(int id);
  bool remove(int id);
  void putMany(List<CheckInEntity> checkins);
  List<CheckInEntity> findByProperty(String propertyId);
  List<CheckInEntity> findActiveByProperty(String propertyId);
  CheckInEntity? findByUuid(String uuid);
}
