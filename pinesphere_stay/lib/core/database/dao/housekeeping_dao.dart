import '../../../features/housekeeping/domain/models/housekeeping_task_entity.dart';

abstract class IHousekeepingDao {
  int put(HousekeepingTaskEntity entity);
  void putMany(List<HousekeepingTaskEntity> entities);
  List<HousekeepingTaskEntity> getAll();
  HousekeepingTaskEntity? get(int id);
  bool remove(int id);
  List<HousekeepingTaskEntity> queryTasks(String propertyId, {String? status, String? staffId});
}
