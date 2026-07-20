import '../../../features/housekeeping/domain/models/housekeeping_task_entity.dart';
import 'housekeeping_dao.dart';

class HousekeepingDaoWeb implements IHousekeepingDao {
  final Map<int, HousekeepingTaskEntity> _storage = {};
  int _counter = 1;

  @override
  int put(HousekeepingTaskEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  void putMany(List<HousekeepingTaskEntity> entities) {
    for (var entity in entities) {
      put(entity);
    }
  }

  @override
  List<HousekeepingTaskEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  HousekeepingTaskEntity? get(int id) {
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
  List<HousekeepingTaskEntity> queryTasks(String propertyId, {String? status, String? staffId}) {
    return _storage.values.where((e) {
      bool match = e.propertyId == propertyId;
      if (status != null) {
        match = match && e.status == status;
      }
      if (staffId != null && staffId.isNotEmpty) {
        match = match && e.assignedStaffId == staffId;
      }
      return match;
    }).toList();
  }
}
