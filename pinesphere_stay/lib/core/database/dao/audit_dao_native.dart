import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/audit/domain/models/audit_log_entity.dart';
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

  @override
  String? getLatestHash(String? propertyId) {
    Condition<AuditLogEntity> cond;
    if (propertyId != null) {
      cond = AuditLogEntity_.propertyId.equals(propertyId);
    } else {
      cond = AuditLogEntity_.propertyId.isNull();
    }
    final query = _box
        .query(cond)
        .order(AuditLogEntity_.timestamp, flags: Order.descending)
        .build();
    try {
      final latest = query.findFirst();
      return latest?.entryHash;
    } finally {
      query.close();
    }
  }

  @override
  List<AuditLogEntity> queryLogs({String? propertyId, String? moduleName, String? actionType, int limit = 50}) {
    Condition<AuditLogEntity>? condition;
    if (propertyId != null) {
      condition = AuditLogEntity_.propertyId.equals(propertyId);
    }
    if (moduleName != null) {
      final c = AuditLogEntity_.moduleName.equals(moduleName);
      condition = condition == null ? c : condition.and(c);
    }
    if (actionType != null) {
      final c = AuditLogEntity_.actionType.equals(actionType);
      condition = condition == null ? c : condition.and(c);
    }

    final query = (condition == null ? _box.query() : _box.query(condition))
        .order(AuditLogEntity_.timestamp, flags: Order.descending)
        .build();
    try {
      query.limit = limit;
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  List<AuditLogEntity> getChain({String? propertyId}) {
    Condition<AuditLogEntity> cond;
    if (propertyId != null) {
      cond = AuditLogEntity_.propertyId.equals(propertyId);
    } else {
      cond = AuditLogEntity_.propertyId.isNull();
    }
    final query = _box
        .query(cond)
        .order(AuditLogEntity_.timestamp)
        .build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }
}
