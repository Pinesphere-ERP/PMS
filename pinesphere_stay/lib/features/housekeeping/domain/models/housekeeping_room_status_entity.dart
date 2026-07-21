import 'package:objectbox/objectbox.dart';
import '../../../sync/models/sync_entity.dart';

@Entity()
class HousekeepingRoomStatusEntity implements SyncEntity {
  @Id()
  int id = 0;

  @Index()
  String serverId; // maps to 'id' in backend UUID

  @Index()
  String propertyId;

  @Index()
  String roomId;

  String roomNumber;
  String? roomType;
  String? floor;
  String? description;
  String occupancyStatus;
  
  @Index()
  String cleanStatus;
  
  String? priority;
  String? lastCleanedAt;
  String? estimatedCleaningTime;
  String? imageUrlsJson; // JSON string of urls array
  String? createdBy;
  String? updatedBy;

  @override
  @Property(type: PropertyType.date)
  DateTime createdAt;

  @override
  @Property(type: PropertyType.date)
  DateTime lastModifiedHlc;

  @override
  bool isDeleted;

  @override
  @Transient()
  bool get hasUnsyncedChanges => false; 

  @override
  String get syncId => serverId;

  HousekeepingRoomStatusEntity({
    this.id = 0,
    required this.serverId,
    required this.propertyId,
    required this.roomId,
    required this.roomNumber,
    this.roomType,
    this.floor,
    this.description,
    required this.occupancyStatus,
    required this.cleanStatus,
    this.priority,
    this.lastCleanedAt,
    this.estimatedCleaningTime,
    this.imageUrlsJson,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.lastModifiedHlc,
    this.isDeleted = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': serverId,
      'property_id': propertyId,
      'room_id': roomId,
      'room_number': roomNumber,
      'room_type': roomType,
      'floor': floor,
      'description': description,
      'occupancy_status': occupancyStatus,
      'clean_status': cleanStatus,
      'priority': priority,
      'last_cleaned_at': lastCleanedAt,
      'estimated_cleaning_time': estimatedCleaningTime,
      'image_urls_json': imageUrlsJson,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toIso8601String(),
      'last_modified_hlc': lastModifiedHlc.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory HousekeepingRoomStatusEntity.fromJson(Map<String, dynamic> json) {
    return HousekeepingRoomStatusEntity(
      serverId: json['id'] as String,
      propertyId: json['property_id'] as String,
      roomId: json['room_id'] as String,
      roomNumber: json['room_number'] as String,
      roomType: json['room_type'] as String?,
      floor: json['floor'] as String?,
      description: json['description'] as String?,
      occupancyStatus: json['occupancy_status'] as String? ?? 'vacant',
      cleanStatus: json['clean_status'] as String? ?? 'clean',
      priority: json['priority'] as String?,
      lastCleanedAt: json['last_cleaned_at'] as String?,
      estimatedCleaningTime: json['estimated_cleaning_time'] as String?,
      imageUrlsJson: json['image_urls_json'] as String?,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now().toUtc(),
      lastModifiedHlc: json['last_modified_hlc'] != null ? DateTime.parse(json['last_modified_hlc']) : DateTime.now().toUtc(),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }
}
