import '../../../features/settings/domain/models/settings_entity.dart';

abstract class ISettingsDao {
  int put(SettingsEntity entity);
  List<SettingsEntity> getAll();
  SettingsEntity? get(int id);
  bool remove(int id);
}
