import '../../../features/housekeeping/domain/models/maintenance_ticket_entity.dart';
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

  @override
  List<MaintenanceTicketEntity> queryTickets(String propertyId, {String? status, String? category}) {
    return _storage.values.where((e) {
      bool match = e.propertyId == propertyId;
      if (status != null) {
        match = match && e.status == status;
      }
      if (category != null && category.isNotEmpty) {
        match = match && e.category == category;
      }
      return match;
    }).toList();
  }
}
