import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/housekeeping/domain/models/housekeeping_task_entity.dart';
import 'housekeeping_dao.dart';

class HousekeepingDaoNative implements IHousekeepingDao {
  final Box<HousekeepingTaskEntity> _box;

  HousekeepingDaoNative(this._box);

  @override
  int put(HousekeepingTaskEntity entity) {
    return _box.put(entity);
  }

  @override
  void putMany(List<HousekeepingTaskEntity> entities) {
    _box.putMany(entities);
  }

  @override
  List<HousekeepingTaskEntity> getAll() {
    return _box.getAll();
  }

  @override
  HousekeepingTaskEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }

  @override
  List<HousekeepingTaskEntity> queryTasks(String propertyId, {String? status, String? staffId}) {
    var condition = HousekeepingTaskEntity_.propertyId.equals(propertyId);
    if (status != null) {
      condition = condition & HousekeepingTaskEntity_.status.equals(status);
    }
    
    final query = _box.query(condition).build();
    final results = query.find();
    query.close();
    
    if (staffId != null && staffId.isNotEmpty) {
      return results.where((e) => e.assignedStaffId == staffId).toList();
    }
    return results;
  }
}
