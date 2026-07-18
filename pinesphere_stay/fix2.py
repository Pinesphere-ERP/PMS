import os

def replace_in_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old, new in replacements:
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")
    else:
        print(f"No changes in {filepath}")

# 1. user_dao_web.dart
user_dao_web_path = r"lib\core\database\dao\user_dao_web.dart"
user_dao_web_add = """
  @override
  UserEntity? getByEmail(String email) {
    try {
      return _storage.values.firstWhere((e) => e.email == email);
    } catch (_) {
      return null;
    }
  }
}"""
replace_in_file(user_dao_web_path, [("}\n", user_dao_web_add + "\n")])

# 2. login_screen.dart
login_path = r"lib\features\auth\presentation\screens\login_screen.dart"
replace_in_file(login_path, [("(_, __, ___) =>", "(context, error, stackTrace) =>")])

# 3. housekeeping_screen.dart & kitchen_screen.dart
hs_path = r"lib\features\housekeeping\presentation\screens\housekeeping_screen.dart"
replace_in_file(hs_path, [("HousekeepingScreen({Key? key}) : super(key: key);", "HousekeepingScreen({super.key});")])

ks_path = r"lib\features\kitchen\presentation\screens\kitchen_screen.dart"
replace_in_file(ks_path, [("KitchenScreen({Key? key}) : super(key: key);", "KitchenScreen({super.key});")])

# 4. prefer_conditional_assignment in user_repository.dart
user_repo_path = r"lib\features\user_role_management\data\repository\user_repository.dart"
with open(user_repo_path, 'r', encoding='utf-8') as f:
    user_repo_content = f.read()
# Replace `if (localUsers == null) {\n      localUsers = [];\n    }` with `localUsers ??= [];`
new_user_repo = user_repo_content.replace("if (localUsers == null) {\n      localUsers = [];\n    }", "localUsers ??= [];")
new_user_repo = new_user_repo.replace("if (localUsers == null) localUsers = [];", "localUsers ??= [];")
# Also duplicate import
lines = new_user_repo.split('\n')
seen_imports = set()
new_lines = []
for line in lines:
    if line.startswith("import "):
        if line in seen_imports:
            continue
        seen_imports.add(line)
    new_lines.append(line)

with open(user_repo_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))
print(f"Updated {user_repo_path}")

# 5. Fix duplicate imports in other files
duplicate_files = [
    r"lib\features\bookings\data\booking_service.dart",
    r"lib\features\checkin\data\checkin_service.dart",
    r"lib\features\checkout\data\checkout_service.dart",
    r"lib\features\reports\data\kpi_aggregation_service.dart",
    r"lib\features\rooms\data\room_service.dart",
    r"lib\features\settings\data\settings_service.dart",
    r"lib\features\sync\data\sync_service.dart",
]

for fp in duplicate_files:
    if os.path.exists(fp):
        with open(fp, 'r', encoding='utf-8') as f:
            lines = f.read().split('\n')
        seen_imports = set()
        new_lines = []
        for line in lines:
            if line.startswith("import "):
                if line in seen_imports:
                    continue
                seen_imports.add(line)
            new_lines.append(line)
        with open(fp, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_lines))
        print(f"Fixed imports in {fp}")

# 6. Unused imports
dashboard_path = r"lib\features\dashboard\presentation\screens\dashboard_screen.dart"
replace_in_file(dashboard_path, [("import '../../../../core/presentation/widgets/premium_card.dart';\n", "")])

guest_service_path = r"lib\features\guests\data\guest_service.dart"
replace_in_file(guest_service_path, [("import 'package:pinesphere_stay/core/database/obx_annotations.dart';\n", "")])

