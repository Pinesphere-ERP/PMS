import 'package:objectbox/objectbox.dart';

@Entity()
class RoomEntity {
  @Id()
  int id = 0;

  /// Server UUID for the room
  @Unique()
  String uuid;

  String name;
  String type; // e.g. "Deluxe", "Standard"
  String status; // e.g. "Vacant", "Occupied", "Cleaning", "Maintenance"
  double pricePerNight;

  /// Used for conflict resolution
  String lastModifiedHlc;

  RoomEntity({
    this.id = 0,
    required this.uuid,
    required this.name,
    required this.type,
    required this.status,
    required this.pricePerNight,
    required this.lastModifiedHlc,
  });
}
