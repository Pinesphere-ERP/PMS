import 'package:pinesphere_stay/core/database/obx_annotations.dart';

@Entity()
class SettingsEntity {
  int id;
  
  @Unique()
  String serverId;
  
  String key;
  String value;

  SettingsEntity({
    this.id = 0,
    required this.serverId,
    required this.key,
    required this.value,
  });
}
