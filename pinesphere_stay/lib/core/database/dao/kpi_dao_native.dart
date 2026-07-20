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

  @override
  KpiSnapshotEntity? findByPropertyAndDate(String propertyId, String dateKey) {
    final query = _box.query(
      KpiSnapshotEntity_.propertyId.equals(propertyId) & KpiSnapshotEntity_.snapshotDate.equals(dateKey),
    ).build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  @override
  Stream<KpiSnapshotEntity?> watchByPropertyAndDate(String propertyId, String dateKey) {
    return _box.query(
      KpiSnapshotEntity_.propertyId.equals(propertyId) & KpiSnapshotEntity_.snapshotDate.equals(dateKey),
    ).watch().map((q) => q.findFirst());
  }

  @override
  List<KpiSnapshotEntity> getRange(String propertyId, String startKey, String endKey) {
    final query = _box.query(
      KpiSnapshotEntity_.propertyId.equals(propertyId) &
          KpiSnapshotEntity_.snapshotDate.greaterOrEqual(startKey) &
          KpiSnapshotEntity_.snapshotDate.lessOrEqual(endKey),
    ).order(KpiSnapshotEntity_.snapshotDate).build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }
}
