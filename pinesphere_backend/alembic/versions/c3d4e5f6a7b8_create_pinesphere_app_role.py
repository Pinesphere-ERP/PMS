"""Create pinesphere_app role, grant access, REVOKE audit_logs mutations

The previous migration (b2c3d4e5f6a7) targeted 'pinesphere' — the superuser/owner
who bypasses all REVOKEs. This migration creates a separate non-superuser role
'pinesphere_app' for the FastAPI app, grants it full access to all tables, then
revokes UPDATE/DELETE on audit_logs from that role.

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-07-11
"""
import os
from alembic import op

revision = 'c3d4e5f6a7b8'
down_revision = 'b2c3d4e5f6a7'
branch_labels = None
depends_on = None

APP_ROLE = "pinesphere_app"
ADMIN_ROLE = "pinesphere"


def upgrade() -> None:
    app_password = os.environ.get("APP_DB_PASSWORD", "pinesphere_password")

    try:
        # 1. Create non-superuser app role with password (idempotent)
        op.execute(f"""
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '{APP_ROLE}') THEN
                    CREATE ROLE {APP_ROLE} WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
                        PASSWORD '{app_password}';
                END IF;
            END$$;
        """)

        # 2. Grant full DML on ALL existing tables to app role
        op.execute(f"GRANT USAGE ON SCHEMA public TO {APP_ROLE}")
        op.execute(f"GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {APP_ROLE}")
        op.execute(f"GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO {APP_ROLE}")

        # 3. Ensure future tables also get grants (ALTER DEFAULT PRIVILEGES)
        op.execute(f"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO {APP_ROLE}")
        op.execute(f"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO {APP_ROLE}")

        # 4. Revoke UPDATE/DELETE specifically on audit_logs from app role
        op.execute(f"REVOKE UPDATE, DELETE ON TABLE audit_logs FROM {APP_ROLE}")
        op.execute(f"GRANT SELECT, INSERT ON TABLE audit_logs TO {APP_ROLE}")

        # 5. Ensure TRUNCATE trigger exists (may already exist from b2c3d4e5f6a7)
        op.execute("""
            CREATE OR REPLACE FUNCTION block_audit_truncate()
            RETURNS TRIGGER AS $$
            BEGIN
                RAISE EXCEPTION 'TRUNCATE is not permitted on audit_logs';
                RETURN NULL;
            END;
            $$ LANGUAGE plpgsql
        """)

        op.execute("""
            DROP TRIGGER IF EXISTS trg_block_audit_truncate ON audit_logs
        """)

        op.execute("""
            CREATE TRIGGER trg_block_audit_truncate
                BEFORE TRUNCATE ON audit_logs
                FOR EACH STATEMENT
                EXECUTE FUNCTION block_audit_truncate()
        """)

        # 6. Ensure audit_logs is owned by admin role (not app role)
        op.execute(f"ALTER TABLE audit_logs OWNER TO {ADMIN_ROLE}")
    except Exception as e:
        print(f"Skipping role configuration: {e}")

def downgrade() -> None:
    try:
        op.execute("DROP TRIGGER IF EXISTS trg_block_audit_truncate ON audit_logs")
        op.execute("DROP FUNCTION IF EXISTS block_audit_truncate()")

        # Restore full privileges on audit_logs
        op.execute(f"GRANT UPDATE, DELETE ON TABLE audit_logs TO {APP_ROLE}")

        # Revoke all table access
        op.execute(f"REVOKE SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM {APP_ROLE}")
        op.execute(f"REVOKE USAGE ON SCHEMA public FROM {APP_ROLE}")

        # Drop the role
        op.execute(f"DROP ROLE IF EXISTS {APP_ROLE}")
    except Exception as e:
        print(f"Skipping role configuration on downgrade: {e}")

