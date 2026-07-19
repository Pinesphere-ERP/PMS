export 'database_service_native.dart' if (dart.library.js_interop) 'database_service_web.dart';
import 'dao/guest_dao.dart';
import 'dao/booking_dao.dart';
import 'dao/room_dao.dart';
import 'dao/checkin_dao.dart';
import 'dao/checkout_dao.dart';
import 'dao/housekeeping_dao.dart';
import 'dao/maintenance_dao.dart';
import 'dao/settings_dao.dart';
import 'dao/kpi_dao.dart';
import 'dao/audit_dao.dart';
import 'dao/sync_dao.dart';
import 'dao/sync_op_dao.dart';
import 'dao/user_dao.dart';
import 'dao/role_perm_dao.dart';
import 'dao/perm_dao.dart';

abstract class IDatabaseService {
  Future<void> init();
  // TODO: Remove store accessor after DAO migration is complete.
  dynamic get store;
  IGuestDao get guestDao;
  IBookingDao get bookingDao;
  IRoomDao get roomDao;
  ICheckinDao get checkinDao;
  ICheckoutDao get checkoutDao;
  IHousekeepingDao get housekeepingDao;
  IMaintenanceDao get maintenanceDao;
  ISettingsDao get settingsDao;
  IKpiDao get kpiDao;
  IAuditDao get auditDao;
  ISyncDao get syncDao;
  ISyncOpDao get syncOpDao;
  IUserDao get userDao;
  IRolePermDao get rolePermDao;
  IPermDao get permDao;
}
