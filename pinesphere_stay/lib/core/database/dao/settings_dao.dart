import '../../../features/settings/domain/models/property_setting_entity.dart';

abstract class ISettingsDao {
  int put(PropertySettingEntity entity);
  List<PropertySettingEntity> getAll();
  PropertySettingEntity? get(int id);
  bool remove(int id);
}
