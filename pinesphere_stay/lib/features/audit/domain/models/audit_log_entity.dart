import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class AuditLogEntity {
  @Id()
  int id = 0;

  @Index()
  String logId;

  @Index()
  String? propertyId;

  String? userId;

  String? deviceId;

  @Index()
  @Property(type: PropertyType.date)
  DateTime timestamp;

  @Index()
  String? moduleName;

  @Index()
  String? actionType;

  String? targetEntity;

  String? targetRecordId;

  String? oldValueSnapshot;

  String? newValueSnapshot;

  String? ipAddress;

  String? previousLogHash;

  String? entryHash;

  AuditLogEntity({
    this.id = 0,
    required this.logId,
    this.propertyId,
    this.userId,
    this.deviceId,
    required this.timestamp,
    this.moduleName,
    this.actionType,
    this.targetEntity,
    this.targetRecordId,
    this.oldValueSnapshot,
    this.newValueSnapshot,
    this.ipAddress,
    this.previousLogHash,
    this.entryHash,
  });
}
