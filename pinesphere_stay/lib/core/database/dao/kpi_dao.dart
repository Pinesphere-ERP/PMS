import '../../../features/reports/domain/models/kpisnapshotentity.dart';

abstract class IKpiDao {
  int put(KpiSnapshotEntity entity);
  List<KpiSnapshotEntity> getAll();
  KpiSnapshotEntity? get(int id);
  bool remove(int id);
}
