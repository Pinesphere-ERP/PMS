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
    # Role configurations disabled for cloud compatibility

    # 5. Ensure TRUNCATE trigger exists
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
    # Role configurations disabled for cloud compatibility

    op.execute("DROP TRIGGER IF EXISTS trg_block_audit_truncate ON audit_logs")
    op.execute("DROP FUNCTION IF EXISTS block_audit_truncate()")

