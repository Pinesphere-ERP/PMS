import 'package:objectbox/objectbox.dart';

@Entity()
class TaskModel {
  @Id()
  int id = 0;

  @Unique()
  String taskId;

  String taskType; // 'cleaning', 'maintenance', 'food'
  String status; // 'pending', 'accepted', 'in_progress', 'completed', 'closed'
  String priority; // 'normal', 'high', 'emergency'
  
  String? roomId;
  String? bookingId;
  String? assignedTo;
  String? requestedByUserId;
  String? requestedByGuestId;
  String? description;
  
  @Property(type: PropertyType.date)
  DateTime? dueAt;
  
  @Property(type: PropertyType.date)
  DateTime? completedAt;
  
  String? photos; // JSON list of URLs
  String? remarks;

  // Sync fields
  String syncStatus; // 'pending', 'synced', 'error'
  @Property(type: PropertyType.date)
  DateTime? lastSyncedAt;
  int syncVersion;
  
  @Property(type: PropertyType.date)
  DateTime? createdAt;
  @Property(type: PropertyType.date)
  DateTime? updatedAt;

  TaskModel({
    this.id = 0,
    required this.taskId,
    required this.taskType,
    this.status = 'pending',
    this.priority = 'normal',
    this.roomId,
    this.bookingId,
    this.assignedTo,
    this.requestedByUserId,
    this.requestedByGuestId,
    this.description,
    this.dueAt,
    this.completedAt,
    this.photos,
    this.remarks,
    this.syncStatus = 'synced',
    this.lastSyncedAt,
    this.syncVersion = 1,
    this.createdAt,
    this.updatedAt,
  });
}
