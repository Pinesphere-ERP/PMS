"""Add device_id, ip_address columns and compound indexes to audit_logs

Revision ID: a1b2c3d4e5f6
Revises: d7e3f0a1b2c4
Create Date: 2026-07-11
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID as PGUUID

revision = 'a1b2c3d4e5f6'
down_revision = 'd7e3f0a1b2c4'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add device_id column (VARCHAR, no FK — device UID, not a DB record)
    op.add_column('audit_logs', sa.Column('device_id', sa.String(length=100), nullable=True))

    # Add ip_address column (VARCHAR(45) — supports IPv6)
    op.add_column('audit_logs', sa.Column('ip_address', sa.String(length=45), nullable=True))

    # Add compound index for property-scoped queries sorted by time
    op.create_index(
        'ix_audit_logs_property_timestamp',
        'audit_logs',
        ['property_id', 'timestamp'],
        unique=False,
    )

    # Add compound index for entity-record lookups
    op.create_index(
        'ix_audit_logs_target',
        'audit_logs',
        ['target_entity', 'target_record_id'],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index('ix_audit_logs_target', table_name='audit_logs')
    op.drop_index('ix_audit_logs_property_timestamp', table_name='audit_logs')
    op.drop_column('audit_logs', 'ip_address')
    op.drop_column('audit_logs', 'device_id')
