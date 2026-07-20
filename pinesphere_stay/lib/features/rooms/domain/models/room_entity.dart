import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class RoomEntity {
  @Id()
  int id = 0;

  /// Server UUID for the room
  @Unique()
  String serverId;
  String? tenantId;

  @Index()
  String propertyId;

  String name;
  String type; // e.g. "Deluxe", "Standard"
  
  @Index()
  String status; // e.g. "Vacant", "Occupied", "Cleaning", "Maintenance"
  
  double pricePerNight;

  /// Used for conflict resolution
  String syncStatus;
  String lastModifiedHlc;
  bool isDeleted;
  @Property(type: PropertyType.date)
  DateTime? createdAt;
  @Property(type: PropertyType.date)
  DateTime? updatedAt;
  @Property(type: PropertyType.date)
  DateTime? deletedAt;

  RoomEntity({
    this.id = 0,
    required this.serverId,
    this.tenantId,
    this.propertyId = '',
    required this.name,
    required this.type,
    required this.status,
    required this.pricePerNight,
    this.syncStatus = 'Pending',
    required this.lastModifiedHlc,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
}
