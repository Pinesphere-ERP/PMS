import 'package:objectbox/objectbox.dart';

@Entity()
class DeviceConfigEntity {
  @Id()
  int id = 0;

  @Unique()
  String deviceUid;

  bool biometricEnabled;
  int syncIntervalMins;
  String thermalPrinterMac;
  String localLogLevel;
  String lastModifiedHlc;

  DeviceConfigEntity({
    this.id = 0,
    required this.deviceUid,
    this.biometricEnabled = false,
    this.syncIntervalMins = 15,
    this.thermalPrinterMac = '',
    this.localLogLevel = 'INFO',
    required this.lastModifiedHlc,
  });
}
