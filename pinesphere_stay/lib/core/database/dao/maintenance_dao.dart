import '../../../features/housekeeping/domain/entities/maintenanceticketentity.dart';

abstract class IMaintenanceDao {
  int put(MaintenanceTicketEntity entity);
  List<MaintenanceTicketEntity> getAll();
  MaintenanceTicketEntity? get(int id);
  bool remove(int id);
}
