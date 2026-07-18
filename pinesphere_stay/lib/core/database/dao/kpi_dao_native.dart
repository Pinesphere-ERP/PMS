import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/reports/domain/models/kpi_snapshot_entity.dart';
import 'kpi_dao.dart';

class KpiDaoNative implements IKpiDao {
  final Box<KpiSnapshotEntity> _box;

  KpiDaoNative(this._box);

  @override
  int put(KpiSnapshotEntity entity) {
    return _box.put(entity);
  }

  @override
  List<KpiSnapshotEntity> getAll() {
    return _box.getAll();
  }

  @override
  KpiSnapshotEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
