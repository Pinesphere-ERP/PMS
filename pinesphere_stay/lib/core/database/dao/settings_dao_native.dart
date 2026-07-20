import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/settings/domain/models/property_setting_entity.dart';
import 'settings_dao.dart';

class SettingsDaoNative implements ISettingsDao {
  final Box<PropertySettingEntity> _box;

  SettingsDaoNative(this._box);

  @override
  int put(PropertySettingEntity entity) {
    return _box.put(entity);
  }

  @override
  List<PropertySettingEntity> getAll() {
    return _box.getAll();
  }

  @override
  PropertySettingEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
