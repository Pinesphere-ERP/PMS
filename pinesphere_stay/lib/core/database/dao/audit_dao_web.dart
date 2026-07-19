import '../../../features/audit/domain/models/audit_log_entity.dart';
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

  @override
  String? getLatestHash(String? propertyId) {
    final list = _storage.values.where((e) => propertyId == null ? e.propertyId == null : e.propertyId == propertyId).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.first.entryHash;
  }

  @override
  List<AuditLogEntity> queryLogs({String? propertyId, String? moduleName, String? actionType, int limit = 50}) {
    final list = _storage.values.where((e) {
      if (propertyId != null && e.propertyId != propertyId) return false;
      if (moduleName != null && e.moduleName != moduleName) return false;
      if (actionType != null && e.actionType != actionType) return false;
      return true;
    }).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(limit).toList();
  }

  @override
  List<AuditLogEntity> getChain({String? propertyId}) {
    final list = _storage.values.where((e) => propertyId == null ? e.propertyId == null : e.propertyId == propertyId).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }
}
