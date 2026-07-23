import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class HousekeepingTaskEntity {
  @Id()
  int id = 0;

  @Unique()
  String serverId;
  String roomId;
  @Index()
  String propertyId;
  String roomNumber;
  String bookingId;
  String guestId;
  String createdBy;
  String assignedStaffId;
  String assignedStaffName;
  @Index()
  String status;
  String priority;
  String startedAt;
  String startedBy;
  int duration;
  String checklistStatus;
  String remarks;
  String beforePhoto;
  String afterPhoto;
  String completedAt;
  String inspectedBy;
  String inspectionResult;
  String inspectionRemarks;
  String inspectedAt;
  String createdAt;
  String lastModifiedHlc;

  HousekeepingTaskEntity({
    this.id = 0,
    required this.serverId,
    required this.roomId,
    this.propertyId = '',
    this.roomNumber = '',
    this.bookingId = '',
    this.guestId = '',
    this.createdBy = '',
    this.assignedStaffId = '',
    this.assignedStaffName = '',
    this.status = 'pending',
    this.priority = 'medium',
    this.startedAt = '',
    this.startedBy = '',
    this.duration = 0,
    this.checklistStatus = '',
    this.remarks = '',
    this.beforePhoto = '',
    this.afterPhoto = '',
    this.completedAt = '',
    this.inspectedBy = '',
    this.inspectionResult = '',
    this.inspectionRemarks = '',
    this.inspectedAt = '',
    this.createdAt = '',
    required this.lastModifiedHlc,
  });
}
