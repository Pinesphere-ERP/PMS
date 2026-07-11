import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:objectbox/objectbox.dart';
import '../domain/models/audit_log_entity.dart';
import '../../../objectbox.g.dart';


final _genesisHash = '0' * 64;


String _computeEntryHash({
  required String previousHash,
  required DateTime timestamp,
  String? userId,
  required String actionType,
  String? oldValue,
  String? newValue,
}) {
  final parts = [
    previousHash,
    timestamp.toIso8601String(),
    userId ?? '',
    actionType,
    oldValue ?? '',
    newValue ?? '',
  ];
  final raw = parts.join('||');
  return sha256.convert(utf8.encode(raw)).toString();
}

class AuditService {
  late final Store _store;
  late final Box<AuditLogEntity> _auditBox;

  void initialize(Store store) {
    _store = store;
    _auditBox = _store.box<AuditLogEntity>();
  }

  String _getPreviousHash(String? propertyId) {
    final query = _auditBox
        .query(AuditLogEntity_.propertyId.equals(propertyId ?? ''))
        .order(AuditLogEntity_.timestamp, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();

    if (results.isEmpty) return _genesisHash;
    return results.first.entryHash ?? _genesisHash;
  }

  AuditLogEntity log({
    required String logId,
    String? propertyId,
    String? userId,
    String? deviceId,
    required DateTime timestamp,
    required String moduleName,
    required String actionType,
    required String targetEntity,
    required String targetRecordId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? ipAddress,
  }) {
    final prevHash = _getPreviousHash(propertyId);
    final oldJson = oldValue != null ? jsonEncode(oldValue) : null;
    final newJson = newValue != null ? jsonEncode(newValue) : null;

    final entryHash = _computeEntryHash(
      previousHash: prevHash,
      timestamp: timestamp,
      userId: userId,
      actionType: actionType,
      oldValue: oldJson,
      newValue: newJson,
    );

    final entry = AuditLogEntity(
      logId: logId,
      propertyId: propertyId,
      userId: userId,
      deviceId: deviceId,
      timestamp: timestamp,
      moduleName: moduleName,
      actionType: actionType,
      targetEntity: targetEntity,
      targetRecordId: targetRecordId,
      oldValueSnapshot: oldJson,
      newValueSnapshot: newJson,
      ipAddress: ipAddress,
      previousLogHash: prevHash,
      entryHash: entryHash,
    );

    _auditBox.put(entry);
    return entry;
  }

  List<AuditLogEntity> queryLogs({
    String? propertyId,
    String? moduleName,
    String? actionType,
    int limit = 50,
  }) {
    Condition<AuditLogEntity>? cond;
    if (propertyId != null) {
      cond = AuditLogEntity_.propertyId.equals(propertyId);
    }
    if (moduleName != null) {
      final moduleCond = AuditLogEntity_.moduleName.equals(moduleName);
      cond = cond == null ? moduleCond : cond & moduleCond;
    }
    if (actionType != null) {
      final actionCond = AuditLogEntity_.actionType.equals(actionType);
      cond = cond == null ? actionCond : cond & actionCond;
    }

    final qBuilder = _auditBox.query(cond);
    qBuilder.order(AuditLogEntity_.timestamp, flags: Order.descending);
    final built = qBuilder.build();
    final results = built.find();
    built.close();
    return results.take(limit).toList();
  }

  bool verifyChain({String? propertyId}) {
    final query = _auditBox
        .query(AuditLogEntity_.propertyId.equals(propertyId ?? ''))
        .order(AuditLogEntity_.timestamp)
        .build();
    final entries = query.find();
    query.close();

    if (entries.isEmpty) return true;

    var prevHash = _genesisHash;
    for (final entry in entries) {
      final expectedHash = _computeEntryHash(
        previousHash: prevHash,
        timestamp: entry.timestamp,
        userId: entry.userId,
        actionType: entry.actionType ?? '',
        oldValue: entry.oldValueSnapshot,
        newValue: entry.newValueSnapshot,
      );
      if (entry.entryHash != expectedHash) return false;
      prevHash = entry.entryHash ?? _genesisHash;
    }
    return true;
  }
}
