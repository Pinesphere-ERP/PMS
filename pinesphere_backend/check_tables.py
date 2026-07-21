import sqlite3
conn = sqlite3.connect('pinesphere.db')
cursor = conn.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
all_tables = [r[0] for r in cursor.fetchall()]
manager_tables = [t for t in all_tables if any(x in t for x in ['manager', 'room_block', 'staff_shift'])]
print('Manager tables in SQLite DB:')
for t in manager_tables:
    print(f'  - {t}')
    cursor.execute(f'PRAGMA table_info({t})')
    cols = [r[1] for r in cursor.fetchall()]
    print(f'    Columns: {cols}')
print()
print(f'Total tables: {len(all_tables)}')
conn.close()
