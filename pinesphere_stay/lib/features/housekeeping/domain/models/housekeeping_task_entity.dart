import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class HousekeepingTaskEntity {
  @Id()
  int id = 0;

  @Unique()
  String uuid;
  String roomId;
  @Index()
  String propertyId;
  String roomNumber;
  String assignedStaffId;
  String assignedStaffName;
  @Index()
  String status;
  String priority;
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
    required this.uuid,
    required this.roomId,
    this.propertyId = '',
    this.roomNumber = '',
    this.assignedStaffId = '',
    this.assignedStaffName = '',
    this.status = 'pending',
    this.priority = 'medium',
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
