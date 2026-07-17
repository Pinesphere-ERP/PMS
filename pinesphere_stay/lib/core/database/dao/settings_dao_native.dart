import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/settings/domain/models/settingsentity.dart';
import 'settings_dao.dart';

class SettingsDaoNative implements ISettingsDao {
  final Box<SettingsEntity> _box;

  SettingsDaoNative(this._box);

  @override
  int put(SettingsEntity entity) {
    return _box.put(entity);
  }

  @override
  List<SettingsEntity> getAll() {
    return _box.getAll();
  }

  @override
  SettingsEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
