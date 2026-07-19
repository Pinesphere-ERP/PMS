import 'database_service.dart';
import 'dao/guest_dao.dart';
import 'dao/guest_dao_web.dart';
import 'dao/booking_dao.dart';
import 'dao/booking_dao_web.dart';
import 'dao/room_dao.dart';
import 'dao/room_dao_web.dart';
import 'dao/checkin_dao.dart';
import 'dao/checkin_dao_web.dart';
import 'dao/checkout_dao.dart';
import 'dao/checkout_dao_web.dart';
import 'dao/housekeeping_dao.dart';
import 'dao/housekeeping_dao_web.dart';
import 'dao/maintenance_dao.dart';
import 'dao/maintenance_dao_web.dart';
import 'dao/settings_dao.dart';
import 'dao/settings_dao_web.dart';
import 'dao/kpi_dao.dart';
import 'dao/kpi_dao_web.dart';
import 'dao/audit_dao.dart';
import 'dao/audit_dao_web.dart';
import 'dao/sync_queue_dao.dart';
import 'dao/sync_queue_dao_web.dart';
import 'dao/sync_op_dao.dart';
import 'dao/sync_op_dao_web.dart';
import 'dao/user_dao.dart';
import 'dao/user_dao_web.dart';
import 'dao/role_perm_dao.dart';
import 'dao/role_perm_dao_web.dart';
import 'dao/perm_dao.dart';
import 'dao/perm_dao_web.dart';

class DatabaseService implements IDatabaseService {
  late final IGuestDao _guestDao;
  late final IBookingDao _bookingDao;
  late final IRoomDao _roomDao;
  late final ICheckinDao _checkinDao;
  late final ICheckoutDao _checkoutDao;
  late final IHousekeepingDao _housekeepingDao;
  late final IMaintenanceDao _maintenanceDao;
  late final ISettingsDao _settingsDao;
  late final IKpiDao _kpiDao;
  late final IAuditDao _auditDao;
  late final ISyncQueueDao _syncQueueDao;
  late final ISyncOpDao _syncOpDao;
  late final IUserDao _userDao;
  late final IRolePermDao _rolePermDao;
  late final IPermDao _permDao;

  @override
  Future<void> init() async {
    _guestDao = GuestDaoWeb();
    _bookingDao = BookingDaoWeb();
    _roomDao = RoomDaoWeb();
    _checkinDao = CheckinDaoWeb();
    _checkoutDao = CheckoutDaoWeb();
    _housekeepingDao = HousekeepingDaoWeb();
    _maintenanceDao = MaintenanceDaoWeb();
    _settingsDao = SettingsDaoWeb();
    _kpiDao = KpiDaoWeb();
    _auditDao = AuditDaoWeb();
    _syncQueueDao = SyncQueueDaoWeb();
    _syncOpDao = SyncOpDaoWeb();
    _userDao = UserDaoWeb();
    _rolePermDao = RolePermDaoWeb();
    _permDao = PermDaoWeb();
  }

  @override
  // TODO: Remove store accessor after DAO migration is complete.
  dynamic get store => null;

  @override
  T runInTransaction<T>(T Function() action) {
    // Web has no native transaction support, execute synchronously
    return action();
  }

  @override
  IGuestDao get guestDao => _guestDao;

  @override
  IBookingDao get bookingDao => _bookingDao;

  @override
  IRoomDao get roomDao => _roomDao;

  @override
  ICheckinDao get checkinDao => _checkinDao;

  @override
  ICheckoutDao get checkoutDao => _checkoutDao;

  @override
  IHousekeepingDao get housekeepingDao => _housekeepingDao;

  @override
  IMaintenanceDao get maintenanceDao => _maintenanceDao;

  @override
  ISettingsDao get settingsDao => _settingsDao;

  @override
  IKpiDao get kpiDao => _kpiDao;

  @override
  IAuditDao get auditDao => _auditDao;

  @override
  ISyncQueueDao get syncQueueDao => _syncQueueDao;

  @override
  ISyncOpDao get syncOpDao => _syncOpDao;

  @override
  IUserDao get userDao => _userDao;

  @override
  IRolePermDao get rolePermDao => _rolePermDao;

  @override
  IPermDao get permDao => _permDao;
}
