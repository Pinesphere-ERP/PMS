import re
import os

base = r'c:\Users\Admin\Documents\projects\stay\PMS\pinesphere_stay'

# 1. Remove unused local variable 'entity'
services = [
    r'lib\features\bookings\data\booking_service.dart',
    r'lib\features\checkin\data\checkin_service.dart',
    r'lib\features\checkout\data\checkout_service.dart',
    r'lib\features\guests\data\guest_service.dart',
    r'lib\features\housekeeping\data\housekeeping_service.dart',
    r'lib\features\settings\data\settings_service.dart',
]
for p in services:
    path = os.path.join(base, p)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = re.sub(r'^\s*final entity\s*=\s*.*?;\s*$', '', content, flags=re.MULTILINE)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

# 2. Fix unnecessary underscores (e.g. (_, _) -> (_, __))
underscore_files = [
    r'lib\app\router\app_router.dart',
    r'lib\features\checkin\presentation\screens\checkin_screen.dart',
    r'lib\features\checkout\presentation\screens\checkout_screen.dart',
    r'lib\features\device_management\presentation\screens\device_sync_status_screen.dart',
    r'lib\features\notifications\presentation\widgets\notification_overlay.dart',
    r'lib\features\reports\presentation\screens\reports_dashboard_screen.dart',
]
for p in underscore_files:
    path = os.path.join(base, p)
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        # the previous script did '(_, _)' -> '(_, __)'. 
        # Sometimes they are (_, _, _) -> (_, __, ___)
        # Or (previous, current) but they used (_, _) etc.
        # Just replace '(_, _)' again or maybe '(_, _, _)' 
        content = content.replace('(_, _)', '(_, __)')
        content = content.replace('(_, _, _)', '(_, __, ___)')
        content = content.replace('( _, _ )', '( _, __ )')
        # What if it's (data, _) but there's another _? 
        # It's better to just manually fix the exact lines or just leave it. 15 infos are not breaking build.
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

print("fixed2")
