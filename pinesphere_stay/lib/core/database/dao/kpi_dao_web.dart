import '../../../features/reports/domain/models/kpisnapshotentity.dart';
import 'kpi_dao.dart';

class KpiDaoWeb implements IKpiDao {
  final Map<int, KpiSnapshotEntity> _storage = {};
  int _counter = 1;

  @override
  int put(KpiSnapshotEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<KpiSnapshotEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  KpiSnapshotEntity? get(int id) {
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
}
