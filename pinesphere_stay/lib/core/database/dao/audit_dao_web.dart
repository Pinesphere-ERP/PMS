import '../../../features/audit/domain/entities/auditlogentity.dart';
import 'audit_dao.dart';

class AuditDaoWeb implements IAuditDao {
  final Map<int, AuditLogEntity> _storage = {};
  int _counter = 1;

  @override
  int put(AuditLogEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<AuditLogEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  AuditLogEntity? get(int id) {
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
