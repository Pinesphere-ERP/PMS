import 'dart:convert';
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
  /// JSON-encoded `Map<String, bool>` — use [checklistStatusMap] getter for typed access
  String checklistStatus;
  String remarks;
  String completionNotes;
  String beforePhoto;
  String afterPhoto;
  String completedAt;
  // Inspection
  String inspectedBy;
  String inspectionResult;
  String inspectionRemarks;
  String inspectedAt;
  // Denormalized for dashboard display
  String checkoutTime;
  String guestName;
  // Timestamps
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
    this.completionNotes = '',
    this.beforePhoto = '',
    this.afterPhoto = '',
    this.completedAt = '',
    this.inspectedBy = '',
    this.inspectionResult = '',
    this.inspectionRemarks = '',
    this.inspectedAt = '',
    this.checkoutTime = '',
    this.guestName = '',
    this.createdAt = '',
    required this.lastModifiedHlc,
  });

  /// Returns the checklist as a typed `Map<String, bool>`, or null if not set.
  Map<String, bool>? get checklistStatusMap {
    if (checklistStatus.isEmpty) return null;
    try {
      final decoded = json.decode(checklistStatus) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v == true));
    } catch (_) {
      return null;
    }
  }
}
