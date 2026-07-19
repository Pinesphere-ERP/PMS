import os

files = [
    r"lib\features\bookings\data\booking_service.dart",
    r"lib\features\checkin\data\checkin_service.dart",
    r"lib\features\checkout\data\checkout_service.dart",
    r"lib\features\reports\data\kpi_aggregation_service.dart",
    r"lib\features\rooms\data\room_service.dart",
    r"lib\features\settings\data\settings_service.dart",
    r"lib\features\sync\data\sync_service.dart",
]

for fp in files:
    if os.path.exists(fp):
        with open(fp, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Remove import '../../../main.dart';
        new_content = content.replace("import '../../../main.dart';\n", "")
        
        if new_content != content:
            with open(fp, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed {fp}")
