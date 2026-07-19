import '../../../features/audit/domain/models/audit_log_entity.dart';

abstract class IAuditDao {
  int put(AuditLogEntity entity);
  List<AuditLogEntity> getAll();
  AuditLogEntity? get(int id);
  bool remove(int id);
  String? getLatestHash(String? propertyId);
  List<AuditLogEntity> queryLogs({String? propertyId, String? moduleName, String? actionType, int limit = 50});
  List<AuditLogEntity> getChain({String? propertyId});
}
