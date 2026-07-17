import os

daos = [
    ('guest', 'GuestDao'),
    ('booking', 'BookingDao'),
    ('room', 'RoomDao'),
    ('checkin', 'CheckinDao'),
    ('checkout', 'CheckoutDao'),
    ('housekeeping', 'HousekeepingDao'),
    ('maintenance', 'MaintenanceDao'),
    ('settings', 'SettingsDao'),
    ('kpi', 'KpiDao'),
    ('audit', 'AuditDao'),
    ('sync', 'SyncDao'),
    ('sync_op', 'Sync_opDao'),
    ('user', 'UserDao'),
    ('role_perm', 'Role_permDao'),
    ('perm', 'PermDao'),
]

# database_service.dart
with open('lib/core/database/database_service.dart', 'w') as f:
    f.write("export 'database_service_native.dart' if (dart.library.js_interop) 'database_service_web.dart';\n")
    for name, class_name in daos:
        f.write(f"import 'dao/{name}_dao.dart';\n")
    f.write("\n")
    f.write("abstract class IDatabaseService {\n")
    f.write("  Future<void> init();\n")
    for name, class_name in daos:
        f.write(f"  I{class_name} get {name}Dao;\n")
    f.write("}\n")

# database_service_native.dart
with open('lib/core/database/database_service_native.dart', 'w') as f:
    f.write("import 'package:path/path.dart' as p;\n")
    f.write("import 'package:path_provider/path_provider.dart';\n")
    f.write("import 'package:pinesphere_stay/objectbox.g.dart';\n")
    f.write("import 'database_service.dart';\n")
    for name, class_name in daos:
        f.write(f"import 'dao/{name}_dao.dart';\n")
        f.write(f"import 'dao/{name}_dao_native.dart';\n")
    # Entity imports
    f.write("import '../../../features/guests/domain/models/guest_entity.dart';\n")
    f.write("import '../../../features/bookings/domain/models/booking_entity.dart';\n")
    f.write("import '../../../features/rooms/domain/models/room_entity.dart';\n")
    f.write("import '../../../features/checkin/domain/models/checkin_entity.dart';\n")
    f.write("import '../../../features/checkout/domain/models/checkout_entity.dart';\n")
    f.write("import '../../../features/housekeeping/domain/models/housekeeping_task_entity.dart';\n")
    f.write("import '../../../features/housekeeping/domain/models/maintenance_ticket_entity.dart';\n")
    f.write("import '../../../features/settings/domain/models/settings_entity.dart';\n")
    f.write("import '../../../features/reports/domain/models/kpi_snapshot_entity.dart';\n")
    f.write("import '../../../features/audit/domain/models/audit_log_entity.dart';\n")
    f.write("import '../../../features/sync/domain/models/sync_queue_entity.dart';\n")
    f.write("import '../../../core/sync/queue/sync_operation.dart';\n")
    f.write("import '../../../features/user_role_management/domain/entities.dart';\n")
    
    f.write("\nclass DatabaseService implements IDatabaseService {\n")
    f.write("  late final Store _store;\n")
    for name, class_name in daos:
        f.write(f"  late final I{class_name} _{name}Dao;\n")
    
    f.write("\n  @override\n  Future<void> init() async {\n")
    f.write("    final docsDir = await getApplicationDocumentsDirectory();\n")
    f.write("    final storePath = p.join(docsDir.path, 'obx-pinesphere');\n")
    f.write("    _store = await openStore(directory: storePath);\n\n")
    
    # Initialization
    f.write("    _guestDao = GuestDaoNative(_store.box<GuestEntity>());\n")
    f.write("    _bookingDao = BookingDaoNative(_store.box<BookingEntity>());\n")
    f.write("    _roomDao = RoomDaoNative(_store.box<RoomEntity>());\n")
    f.write("    _checkinDao = CheckinDaoNative(_store.box<CheckInEntity>());\n")
    f.write("    _checkoutDao = CheckoutDaoNative(_store.box<CheckOutEntity>());\n")
    f.write("    _housekeepingDao = HousekeepingDaoNative(_store.box<HousekeepingTaskEntity>());\n")
    f.write("    _maintenanceDao = MaintenanceDaoNative(_store.box<MaintenanceTicketEntity>());\n")
    f.write("    _settingsDao = SettingsDaoNative(_store.box<SettingsEntity>());\n")
    f.write("    _kpiDao = KpiDaoNative(_store.box<KpiSnapshotEntity>());\n")
    f.write("    _auditDao = AuditDaoNative(_store.box<AuditLogEntity>());\n")
    f.write("    _syncDao = SyncDaoNative(_store.box<SyncQueueEntity>());\n")
    f.write("    _sync_opDao = Sync_opDaoNative(_store.box<SyncOperation>());\n")
    f.write("    _userDao = UserDaoNative(_store.box<UserEntity>());\n")
    f.write("    _role_permDao = Role_permDaoNative(_store.box<RolePermissionEntity>());\n")
    f.write("    _permDao = PermDaoNative(_store.box<PermissionEntity>());\n")
    f.write("  }\n")
    
    for name, class_name in daos:
        f.write(f"\n  @override\n  I{class_name} get {name}Dao => _{name}Dao;\n")
    
    f.write("}\n")

# database_service_web.dart
with open('lib/core/database/database_service_web.dart', 'w') as f:
    f.write("import 'database_service.dart';\n")
    for name, class_name in daos:
        f.write(f"import 'dao/{name}_dao.dart';\n")
        f.write(f"import 'dao/{name}_dao_web.dart';\n")
    f.write("\nclass DatabaseService implements IDatabaseService {\n")
    for name, class_name in daos:
        f.write(f"  late final I{class_name} _{name}Dao;\n")
    
    f.write("\n  @override\n  Future<void> init() async {\n")
    for name, class_name in daos:
        f.write(f"    _{name}Dao = {class_name}DaoWeb();\n")
    f.write("  }\n")
    
    for name, class_name in daos:
        f.write(f"\n  @override\n  I{class_name} get {name}Dao => _{name}Dao;\n")
    f.write("}\n")
