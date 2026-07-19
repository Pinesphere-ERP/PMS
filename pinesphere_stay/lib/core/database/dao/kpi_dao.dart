import '../../../features/reports/domain/models/kpi_snapshot_entity.dart';

abstract class IKpiDao {
  int put(KpiSnapshotEntity entity);
  List<KpiSnapshotEntity> getAll();
  KpiSnapshotEntity? get(int id);
  bool remove(int id);
}
