"""Add device tracking

Revision ID: e6a3c9b7c8d2
Revises: 54518110c55c
Create Date: 2026-07-23 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'e6a3c9b7c8d2'
down_revision: Union[str, Sequence[str], None] = '54518110c55c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Modify existing `devices` table
    op.alter_column('devices', 'property_id',
               existing_type=postgresql.UUID(as_uuid=True),
               nullable=True)
    op.alter_column('devices', 'device_uid',
               existing_type=sa.String(length=128),
               type_=sa.String(length=255),
               existing_nullable=False)
               
    op.add_column('devices', sa.Column('manufacturer', sa.String(length=100), nullable=True))
    op.add_column('devices', sa.Column('device_type', sa.String(length=50), nullable=True))
    op.add_column('devices', sa.Column('platform', sa.String(length=50), nullable=True))
    op.add_column('devices', sa.Column('os_version', sa.String(length=50), nullable=True))
    op.add_column('devices', sa.Column('browser_name', sa.String(length=50), nullable=True))
    op.add_column('devices', sa.Column('browser_version', sa.String(length=50), nullable=True))
    op.add_column('devices', sa.Column('app_version', sa.String(length=50), nullable=True))
    op.add_column('devices', sa.Column('build_number', sa.String(length=50), nullable=True))
    op.add_column('devices', sa.Column('is_trusted', sa.Boolean(), server_default='false', nullable=False))
    op.add_column('devices', sa.Column('first_login_at', sa.DateTime(), nullable=True))
    op.add_column('devices', sa.Column('last_login_at', sa.DateTime(), nullable=True))
    op.add_column('devices', sa.Column('login_count', sa.Integer(), server_default='0', nullable=False))

    # 2. Create `device_login_history` table
    op.create_table('device_login_history',
    sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
    sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
    sa.Column('device_id', postgresql.UUID(as_uuid=True), nullable=False),
    sa.Column('login_timestamp', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.Column('logout_timestamp', sa.DateTime(), nullable=True),
    sa.Column('public_ip', sa.String(length=45), nullable=True),
    sa.Column('network_type', sa.String(length=50), nullable=True),
    sa.Column('isp', sa.String(length=100), nullable=True),
    sa.Column('latitude', sa.Float(), nullable=True),
    sa.Column('longitude', sa.Float(), nullable=True),
    sa.Column('city', sa.String(length=100), nullable=True),
    sa.Column('state', sa.String(length=100), nullable=True),
    sa.Column('country', sa.String(length=100), nullable=True),
    sa.Column('postal_code', sa.String(length=20), nullable=True),
    sa.Column('time_zone', sa.String(length=50), nullable=True),
    sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.ForeignKeyConstraint(['device_id'], ['devices.id'], ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )


def downgrade() -> None:
    op.drop_table('device_login_history')
    op.drop_column('devices', 'login_count')
    op.drop_column('devices', 'last_login_at')
    op.drop_column('devices', 'first_login_at')
    op.drop_column('devices', 'is_trusted')
    op.drop_column('devices', 'build_number')
    op.drop_column('devices', 'app_version')
    op.drop_column('devices', 'browser_version')
    op.drop_column('devices', 'browser_name')
    op.drop_column('devices', 'os_version')
    op.drop_column('devices', 'platform')
    op.drop_column('devices', 'device_type')
    op.drop_column('devices', 'manufacturer')
    
    op.alter_column('devices', 'device_uid',
               existing_type=sa.String(length=255),
               type_=sa.String(length=128),
               existing_nullable=False)
    op.alter_column('devices', 'property_id',
               existing_type=postgresql.UUID(as_uuid=True),
               nullable=False)
