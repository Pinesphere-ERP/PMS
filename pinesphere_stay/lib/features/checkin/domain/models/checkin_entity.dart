import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class CheckInEntity {
  @Id()
  int id = 0;

  @Unique()
  String uuid;
  String bookingId;
  String roomId;
  String guestId;
  String propertyId;
  String staffId;
  String guestName;
  String roomNumber;
  String roomType;
  double deposit;
  double advancePaid;
  bool idVerified;
  String idVerificationNotes;
  String checkedInAt;
  String status;
  String offlineId;
  String specialRequests;
  String vehicleNumber;
  bool parkingRequired;
  String lastModifiedHlc;

  CheckInEntity({
    this.id = 0,
    required this.uuid,
    required this.bookingId,
    required this.roomId,
    required this.guestId,
    this.propertyId = '',
    this.staffId = '',
    this.guestName = '',
    this.roomNumber = '',
    this.roomType = '',
    this.deposit = 0,
    this.advancePaid = 0,
    this.idVerified = false,
    this.idVerificationNotes = '',
    this.checkedInAt = '',
    this.status = 'active',
    this.offlineId = '',
    this.specialRequests = '',
    this.vehicleNumber = '',
    this.parkingRequired = false,
    required this.lastModifiedHlc,
  });
}
