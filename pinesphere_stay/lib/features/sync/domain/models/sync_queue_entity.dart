import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class SyncQueueEntity {
  @Id()
  int id = 0;

  /// E.g. "Room", "Booking"
  String entityType;

  /// The UUID of the entity that was mutated
  String entityId;

  /// "CREATE", "UPDATE", "DELETE"
  String operation;

  /// JSON payload of the mutation
  String payload;

  /// Hybrid Logical Clock timestamp of the mutation
  String hlcTimestamp;

  /// "Pending", "Syncing", "Synced", "Failed", "Conflict"
  @Index()
  String status;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  SyncQueueEntity({
    this.id = 0,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.hlcTimestamp,
    this.status = 'Pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
