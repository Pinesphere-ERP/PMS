import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class BookingEntity {
  @Id()
  int id = 0;

  @Unique()
  String uuid;
  @Index()
  String propertyId;
  String roomId;
  String guestId;
  String guestName;
  String roomNumber;
  String roomType;
  String bookingType;
  String bookingSource;
  @Index()
  String checkInDate;
  String checkOutDate;
  int adults;
  int children;
  int infants;
  double roomRent;
  double deposit;
  double discount;
  double taxes;
  double totalPayable;
  double advancePaid;
  double pendingAmount;
  bool extraBed;
  String guestPreferences;
  String notes;
  String vehicleNumber;
  @Index()
  String bookingStatus;
  String paymentStatus;
  String lastModifiedHlc;

  BookingEntity({
    this.id = 0,
    required this.uuid,
    this.propertyId = '',
    required this.roomId,
    required this.guestId,
    this.guestName = '',
    this.roomNumber = '',
    this.roomType = '',
    this.bookingType = 'online',
    this.bookingSource = '',
    required this.checkInDate,
    required this.checkOutDate,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.roomRent = 0,
    this.deposit = 0,
    this.discount = 0,
    this.taxes = 0,
    this.totalPayable = 0,
    this.advancePaid = 0,
    this.pendingAmount = 0,
    this.extraBed = false,
    this.guestPreferences = '',
    this.notes = '',
    this.vehicleNumber = '',
    this.bookingStatus = 'confirmed',
    this.paymentStatus = 'pending',
    required this.lastModifiedHlc,
  });
}
