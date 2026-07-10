import 'package:objectbox/objectbox.dart';

@Entity()
class KpiSnapshotEntity {
  @Id()
  int id = 0;

  /// Server-assigned UUID; empty until synced
  @Unique(onConflict: ConflictStrategy.replace)
  String uuid;

  /// Property UUID this snapshot belongs to
  @Index()
  String propertyId;

  /// The calendar date this snapshot represents (YYYY-MM-DD)
  @Unique(onConflict: ConflictStrategy.replace)
  String snapshotDate;

  int occupiedRooms;
  int vacantRooms;
  double revenueRoomRent;
  double revenueAddons;
  double expensesAmount;
  double outstandingPayments;
  double gstCollected;

  /// Local-only flag: true when record exists only on-device
  bool isLocalOnly;

  /// HLC timestamp for conflict resolution
  String lastModifiedHlc;

  KpiSnapshotEntity({
    this.id = 0,
    required this.uuid,
    required this.propertyId,
    required this.snapshotDate,
    this.occupiedRooms = 0,
    this.vacantRooms = 0,
    this.revenueRoomRent = 0,
    this.revenueAddons = 0,
    this.expensesAmount = 0,
    this.outstandingPayments = 0,
    this.gstCollected = 0,
    this.isLocalOnly = false,
    required this.lastModifiedHlc,
  });
}
