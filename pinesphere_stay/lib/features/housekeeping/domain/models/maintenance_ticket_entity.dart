import 'package:objectbox/objectbox.dart';

@Entity()
class MaintenanceTicketEntity {
  @Id()
  int id = 0;

  @Unique()
  String uuid;
  String roomId;
  String propertyId;
  String roomNumber;
  String reportedBy;
  String reportedByName;
  String assignedTo;
  String assignedToName;
  String category;
  String priority;
  String issueDescription;
  String status;
  double repairCost;
  String createdAt;
  String resolvedAt;
  String photoUrl;
  String lastModifiedHlc;

  MaintenanceTicketEntity({
    this.id = 0,
    required this.uuid,
    required this.roomId,
    this.propertyId = '',
    this.roomNumber = '',
    this.reportedBy = '',
    this.reportedByName = '',
    this.assignedTo = '',
    this.assignedToName = '',
    required this.category,
    this.priority = 'medium',
    required this.issueDescription,
    this.status = 'open',
    this.repairCost = 0,
    this.createdAt = '',
    this.resolvedAt = '',
    this.photoUrl = '',
    required this.lastModifiedHlc,
  });
}
