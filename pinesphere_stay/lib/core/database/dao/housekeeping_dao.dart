import '../../../features/housekeeping/domain/entities/housekeepingtaskentity.dart';

abstract class IHousekeepingDao {
  int put(HousekeepingTaskEntity entity);
  List<HousekeepingTaskEntity> getAll();
  HousekeepingTaskEntity? get(int id);
  bool remove(int id);
}
