import os

base = r'c:\Users\Admin\Documents\projects\stay\PMS\pinesphere_stay'

# 1. pine_background.dart - add import back
pine = os.path.join(base, r'lib\core\presentation\widgets\design_system\pine_background.dart')
with open(pine, 'r', encoding='utf-8') as f:
    content = f.read()
# Add back the import if missing
if 'package:flutter/material.dart' not in content:
    content = "import 'package:flutter/material.dart';\n" + content
with open(pine, 'w', encoding='utf-8') as f:
    f.write(content)

# 2. add_staff_screen.dart - fix DropdownMenuItem
staff = os.path.join(base, r'lib\features\staff\presentation\screens\add_staff_screen.dart')
with open(staff, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('DropdownMenuItem(initialValue:', 'DropdownMenuItem(value:')
with open(staff, 'w', encoding='utf-8') as f:
    f.write(content)

print("fixed")
