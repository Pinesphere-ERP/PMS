import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinesphere_stay/main.dart';
import '../domain/models/audit_log_entity.dart';
import 'package:pinesphere_stay/objectbox.g.dart';

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

final auditServiceProvider = Provider<AuditService>((ref) {
  return AuditService(databaseService.store);
});

class AuditService {
  late final Box<AuditLogEntity> _auditBox;

  AuditService(Store store) {
    _auditBox = store.box<AuditLogEntity>();
  }

  String _getPreviousHash(String? propertyId) {
    Condition<AuditLogEntity> cond;
    if (propertyId != null) {
      cond = AuditLogEntity_.propertyId.equals(propertyId);
    } else {
      cond = AuditLogEntity_.propertyId.isNull();
    }
    final query = _auditBox
        .query(cond)
        .order(AuditLogEntity_.timestamp, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();

    if (results.isEmpty) return _genesisHash;
    return results.first.entryHash ?? _genesisHash;
  }

  AuditLogEntity log({
    required String moduleName,
    required String actionType,
    required String targetEntity,
    required String targetRecordId,
    String? propertyId,
    String? userId,
    String? deviceId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? ipAddress,
  }) {
    final timestamp = DateTime.now().toUtc();
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
      logId: DateTime.now().millisecondsSinceEpoch.toString(),
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
    Condition<AuditLogEntity>? condition;
    
    if (propertyId != null) {
      final c = AuditLogEntity_.propertyId.equals(propertyId);
      condition = c;
    }
    if (moduleName != null) {
      final c = AuditLogEntity_.moduleName.equals(moduleName);
      condition = condition == null ? c : condition.and(c);
    }
    if (actionType != null) {
      final c = AuditLogEntity_.actionType.equals(actionType);
      condition = condition == null ? c : condition.and(c);
    }

    final query = (condition == null ? _auditBox.query() : _auditBox.query(condition))
        .order(AuditLogEntity_.timestamp, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results.take(limit).toList();
  }

  bool verifyChain({String? propertyId}) {
    Condition<AuditLogEntity> cond;
    if (propertyId != null) {
      cond = AuditLogEntity_.propertyId.equals(propertyId);
    } else {
      cond = AuditLogEntity_.propertyId.isNull();
    }
    final query = _auditBox
        .query(cond)
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
