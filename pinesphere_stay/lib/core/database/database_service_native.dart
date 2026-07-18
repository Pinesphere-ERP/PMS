import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pinesphere_stay/objectbox.g.dart';
import 'database_service.dart';
import 'dao/guest_dao.dart';
import 'dao/guest_dao_native.dart';
import 'dao/booking_dao.dart';
import 'dao/booking_dao_native.dart';
import 'dao/room_dao.dart';
import 'dao/room_dao_native.dart';
import 'dao/checkin_dao.dart';
import 'dao/checkin_dao_native.dart';
import 'dao/checkout_dao.dart';
import 'dao/checkout_dao_native.dart';
import 'dao/housekeeping_dao.dart';
import 'dao/housekeeping_dao_native.dart';
import 'dao/maintenance_dao.dart';
import 'dao/maintenance_dao_native.dart';
import 'dao/settings_dao.dart';
import 'dao/settings_dao_native.dart';
import 'dao/kpi_dao.dart';
import 'dao/kpi_dao_native.dart';
import 'dao/audit_dao.dart';
import 'dao/audit_dao_native.dart';
import 'dao/sync_dao.dart';
import 'dao/sync_dao_native.dart';
import 'dao/sync_op_dao.dart';
import 'dao/sync_op_dao_native.dart';
import 'dao/user_dao.dart';
import 'dao/user_dao_native.dart';
import 'dao/role_perm_dao.dart';
import 'dao/role_perm_dao_native.dart';
import 'dao/perm_dao.dart';
import 'dao/perm_dao_native.dart';
import '../../../features/guests/domain/models/guest_entity.dart';
import '../../../features/bookings/domain/models/booking_entity.dart';
import '../../../features/rooms/domain/models/room_entity.dart';
import '../../../features/checkin/domain/models/checkin_entity.dart';
import '../../../features/checkout/domain/models/checkout_entity.dart';
import '../../../features/housekeeping/domain/models/housekeeping_task_entity.dart';
import '../../../features/housekeeping/domain/models/maintenance_ticket_entity.dart';
import '../../../features/settings/domain/models/settings_entity.dart';
import '../../../features/reports/domain/models/kpi_snapshot_entity.dart';
import '../../../features/audit/domain/models/audit_log_entity.dart';
import '../../../features/sync/domain/models/sync_queue_entity.dart';
import '../../../core/sync/queue/sync_operation.dart';
import '../../../features/user_role_management/domain/entities.dart';

class DatabaseService implements IDatabaseService {
  late final Store _store;
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
  late final ISyncDao _syncDao;
  late final ISync_opDao _sync_opDao;
  late final IUserDao _userDao;
  late final IRole_permDao _role_permDao;
  late final IPermDao _permDao;

  @override
  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final storePath = p.join(docsDir.path, 'obx-pinesphere');
    _store = await openStore(directory: storePath);

    _guestDao = GuestDaoNative(_store.box<GuestEntity>());
    _bookingDao = BookingDaoNative(_store.box<BookingEntity>());
    _roomDao = RoomDaoNative(_store.box<RoomEntity>());
    _checkinDao = CheckinDaoNative(_store.box<CheckInEntity>());
    _checkoutDao = CheckoutDaoNative(_store.box<CheckOutEntity>());
    _housekeepingDao = HousekeepingDaoNative(_store.box<HousekeepingTaskEntity>());
    _maintenanceDao = MaintenanceDaoNative(_store.box<MaintenanceTicketEntity>());
    _settingsDao = SettingsDaoNative(_store.box<SettingsEntity>());
    _kpiDao = KpiDaoNative(_store.box<KpiSnapshotEntity>());
    _auditDao = AuditDaoNative(_store.box<AuditLogEntity>());
    _syncDao = SyncDaoNative(_store.box<SyncQueueEntity>());
    _sync_opDao = Sync_opDaoNative(_store.box<SyncOperation>());
    _userDao = UserDaoNative(_store.box<UserEntity>());
    _role_permDao = Role_permDaoNative(_store.box<RolePermissionEntity>());
    _permDao = PermDaoNative(_store.box<PermissionEntity>());
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
  ISyncDao get syncDao => _syncDao;

  @override
  ISync_opDao get sync_opDao => _sync_opDao;

  @override
  IUserDao get userDao => _userDao;

  @override
  IRole_permDao get role_permDao => _role_permDao;

  @override
  IPermDao get permDao => _permDao;

  @override
  Store get store => _store;
}
