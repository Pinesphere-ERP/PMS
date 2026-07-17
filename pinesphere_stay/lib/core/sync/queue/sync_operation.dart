import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class SyncOperation {
  @Id()
  int id = 0;

  /// E.g., 'property', 'reservation', 'guest'
  String entityType;

  /// The UUID of the entity being modified
  @Index()
  String entityId;

  /// 'create', 'update', 'delete'
  String operationType;

  /// JSON payload of the change
  String payload;

  /// Timestamp when the change occurred locally
  @Property(type: PropertyType.date)
  DateTime createdAt;

  int retryCount;

  /// 'pending', 'in_progress', 'failed', 'completed'
  @Index()
  String status;

  SyncOperation({
    this.id = 0,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.status = 'pending',
  });
}
