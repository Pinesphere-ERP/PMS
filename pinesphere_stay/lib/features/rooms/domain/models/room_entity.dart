import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class RoomEntity {
  @Id()
  int id = 0;

  /// Server UUID for the room
  @Unique()
  String uuid;

  @Index()
  String propertyId;

  String name;
  String type; // e.g. "Deluxe", "Standard"
  
  @Index()
  String status; // e.g. "Vacant", "Occupied", "Cleaning", "Maintenance"
  
  double pricePerNight;

  /// Used for conflict resolution
  String lastModifiedHlc;

  RoomEntity({
    this.id = 0,
    required this.uuid,
    this.propertyId = '',
    required this.name,
    required this.type,
    required this.status,
    required this.pricePerNight,
    required this.lastModifiedHlc,
  });
}
