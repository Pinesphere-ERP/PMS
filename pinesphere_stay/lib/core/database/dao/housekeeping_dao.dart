import '../../../features/housekeeping/domain/models/housekeeping_task_entity.dart';

abstract class IHousekeepingDao {
  int put(HousekeepingTaskEntity entity);
  List<HousekeepingTaskEntity> getAll();
  HousekeepingTaskEntity? get(int id);
  bool remove(int id);
}
