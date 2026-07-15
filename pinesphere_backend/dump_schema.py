import sqlite3
conn = sqlite3.connect('pinesphere.db')
cursor = conn.cursor()
cursor.execute("SELECT sql FROM sqlite_master WHERE type='table' OR type='index';")
for row in cursor.fetchall():
    print(row[0])
