import os
import glob
import re

lib_dir = '/mnt/stuffs/PROJECTS/Pinesphere/pinesphere_stay/lib'

files_to_patch = {
    'bookings/data/booking_service.dart': 'BookingService',
    'checkin/data/checkin_service.dart': 'CheckInService',
    'checkout/data/checkout_service.dart': 'CheckOutService',
    'guests/data/guest_service.dart': 'GuestService',
    'housekeeping/data/housekeeping_service.dart': 'HousekeepingService',
    'rooms/data/room_service.dart': 'RoomService',
    'settings/data/settings_service.dart': 'SettingsService',
}

def patch_file(filepath, class_name):
    with open(filepath, 'r') as f:
        content = f.read()

    # Add import for objectBox if not present
    if "import '../../../main.dart';" not in content and "import '../../../../main.dart';" not in content:
        # Check depth
        depth = filepath.count('/') - lib_dir.count('/') - 1
        import_path = '../' * depth + 'main.dart'
        content = f"import '{import_path}';\n" + content

    provider_name = class_name[0].lower() + class_name[1:]
    
    # We want to replace:
    # return ClassName( ... );
    # with:
    # final service = ClassName( ... );
    # service.initialize(objectBox.store, ref.read(syncServiceProvider));
    # return service;
    
    # Regex to find the return statement inside the provider
    pattern = rf"return {class_name}\((.*?)\);"
    
    def repl(m):
        args = m.group(1)
        return f"final service = {class_name}({args});\n  service.initialize(objectBox.store, ref.read(syncServiceProvider));\n  return service;"

    new_content = re.sub(pattern, repl, content, count=1, flags=re.DOTALL)
    
    with open(filepath, 'w') as f:
        f.write(new_content)

for rel_path, class_name in files_to_patch.items():
    patch_file(os.path.join(lib_dir, 'features', rel_path), class_name)

# Now patch SyncService specifically
sync_path = os.path.join(lib_dir, 'features/sync/data/sync_service.dart')
with open(sync_path, 'r') as f:
    sync_content = f.read()

if "import '../../../main.dart';" not in sync_content:
    sync_content = "import '../../../main.dart';\n" + sync_content

sync_pattern = r"return SyncService\((.*?)\);"
def sync_repl(m):
    args = m.group(1)
    return f"final service = SyncService({args});\n  service.initialize(objectBox.store);\n  return service;"

sync_content = re.sub(sync_pattern, sync_repl, sync_content, count=1, flags=re.DOTALL)
with open(sync_path, 'w') as f:
    f.write(sync_content)

# And KPI aggregation
kpi_path = os.path.join(lib_dir, 'features/reports/data/kpi_aggregation_service.dart')
with open(kpi_path, 'r') as f:
    kpi_content = f.read()
if "import '../../../main.dart';" not in kpi_content:
    kpi_content = "import '../../../main.dart';\n" + kpi_content
kpi_pattern = r"return KpiAggregationService\((.*?)\);"
def kpi_repl(m):
    args = m.group(1)
    return f"final service = KpiAggregationService({args});\n  service.initialize(objectBox.store);\n  return service;"
kpi_content = re.sub(kpi_pattern, kpi_repl, kpi_content, count=1, flags=re.DOTALL)
with open(kpi_path, 'w') as f:
    f.write(kpi_content)

print("Patching complete!")
