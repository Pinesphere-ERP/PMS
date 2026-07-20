import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class CheckOutEntity {
  @Id()
  int id = 0;

  @Unique()
  String serverId;
  String? tenantId;
  String checkinId;
  String bookingId;
  String roomId;
  @Index()
  String propertyId;
  String staffId;
  String guestName;
  String roomNumber;
  String checkoutTime;
  double roomCharges;
  double restaurantCharges;
  double laundryCharges;
  double minibarCharges;
  double damageCharges;
  double miscellaneousCharges;
  double discount;
  double gst;
  double totalAmount;
  double advancePaid;
  double remainingBalance;
  double refundAmount;
  String paymentStatus;
  bool keyReturned;
  bool idReturned;
  bool feedbackSubmitted;
  String remarks;
  String checkoutStatus;
  
  // Sync metadata
  String syncStatus;
  String lastModifiedHlc;
  bool isDeleted;
  @Property(type: PropertyType.date)
  DateTime? createdAt;
  @Property(type: PropertyType.date)
  DateTime? updatedAt;
  @Property(type: PropertyType.date)
  DateTime? deletedAt;

  CheckOutEntity({
    this.id = 0,
    required this.serverId,
    this.tenantId,
    required this.checkinId,
    required this.bookingId,
    required this.roomId,
    this.propertyId = '',
    this.staffId = '',
    this.guestName = '',
    this.roomNumber = '',
    this.checkoutTime = '',
    this.roomCharges = 0,
    this.restaurantCharges = 0,
    this.laundryCharges = 0,
    this.minibarCharges = 0,
    this.damageCharges = 0,
    this.miscellaneousCharges = 0,
    this.discount = 0,
    this.gst = 0,
    this.totalAmount = 0,
    this.advancePaid = 0,
    this.remainingBalance = 0,
    this.refundAmount = 0,
    this.paymentStatus = 'pending',
    this.keyReturned = false,
    this.idReturned = false,
    this.feedbackSubmitted = false,
    this.remarks = '',
    this.checkoutStatus = 'pending',
    this.syncStatus = 'Pending',
    required this.lastModifiedHlc,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
}
