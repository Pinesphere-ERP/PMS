import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class GuestEntity {
  @Id()
  int id = 0;

  @Unique()
  String uuid;
  String propertyId;
  String fullName;
  String mobile;
  String email;
  String address;
  String city;
  String state;
  String country;
  String nationality;
  String dob;
  String gender;
  String idType;
  String idNumber;
  String verificationStatus;
  String emergencyContactName;
  String emergencyContactPhone;
  String lastModifiedHlc;

  GuestEntity({
    this.id = 0,
    required this.uuid,
    this.propertyId = '',
    required this.fullName,
    this.mobile = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.nationality = '',
    this.dob = '',
    this.gender = '',
    this.idType = '',
    this.idNumber = '',
    this.verificationStatus = 'pending',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    required this.lastModifiedHlc,
  });
}
