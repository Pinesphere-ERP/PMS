import os

entities = {
    'room': ('RoomEntity', 'rooms'),
    'checkin': ('CheckInEntity', 'checkin'),
    'checkout': ('CheckOutEntity', 'checkout'),
    'housekeeping': ('HousekeepingTaskEntity', 'housekeeping'),
    'maintenance': ('MaintenanceTicketEntity', 'housekeeping'),
    'settings': ('SettingsEntity', 'settings'),
    'kpi': ('KpiSnapshotEntity', 'reports'),
    'audit': ('AuditLogEntity', 'audit'),
    'sync': ('SyncQueueEntity', 'sync'),
    'sync_op': ('SyncOperation', 'sync'),
    'user': ('UserEntity', 'user_role_management'),
    'role_perm': ('RolePermissionEntity', 'user_role_management'),
    'perm': ('PermissionEntity', 'user_role_management'),
}

dao_dir = 'lib/core/database/dao'
os.makedirs(dao_dir, exist_ok=True)

for name, (entity_name, feature) in entities.items():
    # interface
    with open(f'{dao_dir}/{name}_dao.dart', 'w') as f:
        f.write(f'''import '../../../features/{feature}/domain/{"models" if feature not in ["user_role_management", "checkin", "checkout", "housekeeping", "audit"] else "entities" if feature != "user_role_management" else "entities"}/{entity_name.lower()}.dart';

abstract class I{name.capitalize()}Dao {{
  int put({entity_name} entity);
  List<{entity_name}> getAll();
  {entity_name}? get(int id);
  bool remove(int id);
}}
''')

    # native
    with open(f'{dao_dir}/{name}_dao_native.dart', 'w') as f:
        f.write(f'''import 'package:pinesphere_stay/objectbox.g.dart';
import '../../../features/{feature}/domain/{"models" if feature not in ["user_role_management", "checkin", "checkout", "housekeeping", "audit"] else "entities" if feature != "user_role_management" else "entities"}/{entity_name.lower()}.dart';
import '{name}_dao.dart';

class {name.capitalize()}DaoNative implements I{name.capitalize()}Dao {{
  final Box<{entity_name}> _box;

  {name.capitalize()}DaoNative(this._box);

  @override
  int put({entity_name} entity) {{
    return _box.put(entity);
  }}

  @override
  List<{entity_name}> getAll() {{
    return _box.getAll();
  }}

  @override
  {entity_name}? get(int id) {{
    return _box.get(id);
  }}

  @override
  bool remove(int id) {{
    return _box.remove(id);
  }}
}}
''')

    # web
    with open(f'{dao_dir}/{name}_dao_web.dart', 'w') as f:
        f.write(f'''import '../../../features/{feature}/domain/{"models" if feature not in ["user_role_management", "checkin", "checkout", "housekeeping", "audit"] else "entities" if feature != "user_role_management" else "entities"}/{entity_name.lower()}.dart';
import '{name}_dao.dart';

class {name.capitalize()}DaoWeb implements I{name.capitalize()}Dao {{
  final Map<int, {entity_name}> _storage = {{}};
  int _counter = 1;

  @override
  int put({entity_name} entity) {{
    if (entity.id == 0) {{
      entity.id = _counter++;
    }}
    _storage[entity.id] = entity;
    return entity.id;
  }}

  @override
  List<{entity_name}> getAll() {{
    return _storage.values.toList();
  }}

  @override
  {entity_name}? get(int id) {{
    return _storage[id];
  }}

  @override
  bool remove(int id) {{
    if (_storage.containsKey(id)) {{
      _storage.remove(id);
      return true;
    }}
    return false;
  }}
}}
''')
