import psycopg2

conn = psycopg2.connect('postgresql://neondb_owner:npg_TpsoV0gdryS5@ep-wild-bird-atptd648.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require')
conn.autocommit = True
cur = conn.cursor()

# Get all tables
cur.execute("""
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
""")
tables = cur.fetchall()

for table in tables:
    print(f"Dropping table {table[0]} CASCADE...")
    cur.execute(f'DROP TABLE IF EXISTS "{table[0]}" CASCADE')

# Drop all types (enums)
cur.execute("""
    SELECT typname 
    FROM pg_type t 
    JOIN pg_namespace n ON n.oid = t.typnamespace 
    WHERE n.nspname = 'public' AND t.typtype = 'e'
""")
types = cur.fetchall()
for t in types:
    print(f"Dropping type {t[0]} CASCADE...")
    cur.execute(f'DROP TYPE IF EXISTS "{t[0]}" CASCADE')

print("Database wiped clean!")
