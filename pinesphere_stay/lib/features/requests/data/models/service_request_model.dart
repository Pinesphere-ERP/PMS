import 'package:objectbox/objectbox.dart';

@Entity()
class ServiceRequestModel {
  @Id()
  int id = 0;

  @Unique()
  String requestId;

  String propertyId;
  String? bookingId;
  String? roomId;

  String? requestedByGuestId;
  String? requestedByUserId;

  String requestCategory;
  String title;
  String? description;
  String priority; // 'low', 'normal', 'high', 'emergency'
  String status; // 'pending', 'assigned', 'in_progress', 'completed', 'verified', 'cancelled'

  String? assignedTo;
  
  @Property(type: PropertyType.date)
  DateTime? assignedAt;

  String? completedBy;
  
  @Property(type: PropertyType.date)
  DateTime? completedAt;
  
  String? completionPhotoUrl;

  bool managerVerified;
  String? verifiedBy;
  
  @Property(type: PropertyType.date)
  DateTime? verifiedAt;
  
  String? remarks;

  @Property(type: PropertyType.date)
  DateTime createdAt;
  
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  // Sync fields
  String syncStatus; // 'pending', 'synced', 'error'
  @Property(type: PropertyType.date)
  DateTime? lastSyncedAt;
  int syncVersion;

  ServiceRequestModel({
    this.id = 0,
    required this.requestId,
    required this.propertyId,
    this.bookingId,
    this.roomId,
    this.requestedByGuestId,
    this.requestedByUserId,
    required this.requestCategory,
    required this.title,
    this.description,
    this.priority = 'normal',
    this.status = 'pending',
    this.assignedTo,
    this.assignedAt,
    this.completedBy,
    this.completedAt,
    this.completionPhotoUrl,
    this.managerVerified = false,
    this.verifiedBy,
    this.verifiedAt,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'pending',
    this.lastSyncedAt,
    this.syncVersion = 1,
  });
}
