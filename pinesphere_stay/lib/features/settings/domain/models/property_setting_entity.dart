import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class PropertySettingEntity {
  @Id()
  int id = 0;

  @Unique()
  String uuid;

  String propertyId;
  String settingKey;
  String settingValue;
  String valueType;
  String description;
  String updatedBy;
  int version;
  String lastModifiedHlc;

  PropertySettingEntity({
    this.id = 0,
    required this.uuid,
    required this.propertyId,
    required this.settingKey,
    required this.settingValue,
    this.valueType = 'string',
    this.description = '',
    this.updatedBy = '',
    this.version = 1,
    required this.lastModifiedHlc,
  });
}
