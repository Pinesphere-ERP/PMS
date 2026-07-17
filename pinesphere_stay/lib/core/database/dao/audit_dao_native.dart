import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/audit/domain/entities/auditlogentity.dart';
import 'audit_dao.dart';

class AuditDaoNative implements IAuditDao {
  final Box<AuditLogEntity> _box;

  AuditDaoNative(this._box);

  @override
  int put(AuditLogEntity entity) {
    return _box.put(entity);
  }

  @override
  List<AuditLogEntity> getAll() {
    return _box.getAll();
  }

  @override
  AuditLogEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
