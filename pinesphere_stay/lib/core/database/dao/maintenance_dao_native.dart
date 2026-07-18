import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/housekeeping/domain/models/maintenance_ticket_entity.dart';
import 'maintenance_dao.dart';

class MaintenanceDaoNative implements IMaintenanceDao {
  final Box<MaintenanceTicketEntity> _box;

  MaintenanceDaoNative(this._box);

  @override
  int put(MaintenanceTicketEntity entity) {
    return _box.put(entity);
  }

  @override
  List<MaintenanceTicketEntity> getAll() {
    return _box.getAll();
  }

  @override
  MaintenanceTicketEntity? get(int id) {
    return _box.get(id);
  }

  @override
  bool remove(int id) {
    return _box.remove(id);
  }
}
