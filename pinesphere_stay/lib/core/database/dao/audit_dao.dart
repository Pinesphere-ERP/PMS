import '../../../features/audit/domain/entities/auditlogentity.dart';

abstract class IAuditDao {
  int put(AuditLogEntity entity);
  List<AuditLogEntity> getAll();
  AuditLogEntity? get(int id);
  bool remove(int id);
}
