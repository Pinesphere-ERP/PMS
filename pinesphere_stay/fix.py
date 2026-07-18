import os
import glob
import re

replacements = {
    'IRole_permDao': 'IRolePermDao',
    'Role_permDaoNative': 'RolePermDaoNative',
    'Role_permDaoWeb': 'RolePermDaoWeb',
    'ISync_opDao': 'ISyncOpDao',
    'Sync_opDaoNative': 'SyncOpDaoNative',
    'Sync_opDaoWeb': 'SyncOpDaoWeb',
    'sync_opDao': 'syncOpDao',
    'role_permDao': 'rolePermDao',
    '_sync_opDao': '_syncOpDao',
    '_role_permDao': '_rolePermDao',
    'encryptedSharedPreferences: true,': '',
    "import 'dart:html' as html;": "import 'package:web/web.dart' as web;",
    'html.window.localStorage': 'web.window.localStorage'
}

def fix_files():
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = content
                for old, new in replacements.items():
                    new_content = new_content.replace(old, new)
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed {path}")

if __name__ == '__main__':
    fix_files()
