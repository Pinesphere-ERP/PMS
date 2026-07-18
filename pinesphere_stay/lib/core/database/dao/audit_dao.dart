import '../../../features/audit/domain/models/audit_log_entity.dart';

abstract class IAuditDao {
  int put(AuditLogEntity entity);
  List<AuditLogEntity> getAll();
  AuditLogEntity? get(int id);
  bool remove(int id);
}
