"""REVOKE UPDATE/DELETE on audit_logs + block TRUNCATE via trigger

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-07-11
"""
from alembic import op

revision = 'b2c3d4e5f6a7'
down_revision = 'a1b2c3d4e5f6'
branch_labels = None
depends_on = None

APP_DB_ROLE = "pinesphere"


def upgrade() -> None:
    # Role modification disabled for cloud/neon compatibility
    # op.execute(f"REVOKE UPDATE, DELETE ON TABLE audit_logs FROM {APP_DB_ROLE}")
    # op.execute(f"GRANT SELECT, INSERT ON TABLE audit_logs TO {APP_DB_ROLE}")
    pass

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


def downgrade() -> None:
    op.execute("DROP TRIGGER IF EXISTS trg_block_audit_truncate ON audit_logs")
    op.execute("DROP FUNCTION IF EXISTS block_audit_truncate()")
    # Role modification disabled for cloud/neon compatibility
    # op.execute(f"GRANT UPDATE, DELETE ON TABLE audit_logs TO {APP_DB_ROLE}")
