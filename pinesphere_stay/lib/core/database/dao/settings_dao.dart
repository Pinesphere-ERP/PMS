import '../../../features/settings/domain/models/settingsentity.dart';

abstract class ISettingsDao {
  int put(SettingsEntity entity);
  List<SettingsEntity> getAll();
  SettingsEntity? get(int id);
  bool remove(int id);
}
