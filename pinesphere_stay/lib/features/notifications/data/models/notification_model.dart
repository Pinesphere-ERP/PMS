import 'package:objectbox/objectbox.dart';

@Entity()
class NotificationModel {
  @Id()
  int id = 0;

  @Unique()
  String notificationId;

  String recipientId;
  String title;
  String message;
  String channel; // in_app, whatsapp, push
  String priority; // normal, high, critical
  String status; // unread, read, dismissed
  
  @Property(type: PropertyType.date)
  DateTime? readAt;
  
  String? payload; // JSON string

  // Sync fields
  String syncStatus;
  
  @Property(type: PropertyType.date)
  DateTime createdAt;
  
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  NotificationModel({
    this.id = 0,
    required this.notificationId,
    required this.recipientId,
    required this.title,
    required this.message,
    this.channel = 'in_app',
    this.priority = 'normal',
    this.status = 'unread',
    this.readAt,
    this.payload,
    this.syncStatus = 'synced',
    required this.createdAt,
    required this.updatedAt,
  });
}
