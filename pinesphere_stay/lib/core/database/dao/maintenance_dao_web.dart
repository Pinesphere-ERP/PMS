import '../../../features/housekeeping/domain/entities/maintenanceticketentity.dart';
import 'maintenance_dao.dart';

class MaintenanceDaoWeb implements IMaintenanceDao {
  final Map<int, MaintenanceTicketEntity> _storage = {};
  int _counter = 1;

  @override
  int put(MaintenanceTicketEntity entity) {
    if (entity.id == 0) {
      entity.id = _counter++;
    }
    _storage[entity.id] = entity;
    return entity.id;
  }

  @override
  List<MaintenanceTicketEntity> getAll() {
    return _storage.values.toList();
  }

  @override
  MaintenanceTicketEntity? get(int id) {
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
