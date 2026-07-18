import '../../../features/housekeeping/domain/models/maintenance_ticket_entity.dart';

abstract class IMaintenanceDao {
  int put(MaintenanceTicketEntity entity);
  List<MaintenanceTicketEntity> getAll();
  MaintenanceTicketEntity? get(int id);
  bool remove(int id);
}
