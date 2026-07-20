import '../../../features/settings/domain/models/property_setting_entity.dart';
import 'settings_dao.dart';

class SettingsDaoWeb implements ISettingsDao {
  final Map<int, PropertySettingEntity> _storage = {};
  int _counter = 1;

  @override
  int put(PropertySettingEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<PropertySettingEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  PropertySettingEntity? get(int id) {
    return _storage[id];
  }

  @override
  bool remove(int id) {
    if (_storage.containsKey(id)) {
      _storage.remove(id);
      return true;
    }
    return false;
  }
}
