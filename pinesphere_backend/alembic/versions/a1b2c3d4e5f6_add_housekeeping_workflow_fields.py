"""add housekeeping workflow fields

Revision ID: a1b2c3d4e5f6
Revises: c9b7e813a94c
Create Date: 2026-07-23 14:30:00.000000
"""
from alembic import op
import sqlalchemy as sa

revision = 'a1b2c3d4e5f6'
down_revision = 'c9b7e813a94c'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # check_outs: billing breakdown columns
    op.add_column('check_outs', sa.Column('room_charges', sa.Numeric(10, 2), nullable=True, server_default='0'))
    op.add_column('check_outs', sa.Column('restaurant_charges', sa.Numeric(10, 2), nullable=True, server_default='0'))
    op.add_column('check_outs', sa.Column('laundry_charges', sa.Numeric(10, 2), nullable=True, server_default='0'))
    op.add_column('check_outs', sa.Column('minibar_charges', sa.Numeric(10, 2), nullable=True, server_default='0'))
    op.add_column('check_outs', sa.Column('damage_charges', sa.Numeric(10, 2), nullable=True, server_default='0'))
    op.add_column('check_outs', sa.Column('miscellaneous_charges', sa.Numeric(10, 2), nullable=True, server_default='0'))
    op.add_column('check_outs', sa.Column('discount', sa.Numeric(10, 2), nullable=True, server_default='0'))
    op.add_column('check_outs', sa.Column('gst', sa.Numeric(10, 2), nullable=True, server_default='0'))
    op.add_column('check_outs', sa.Column('refund_amount', sa.Numeric(10, 2), nullable=True, server_default='0'))
    op.add_column('check_outs', sa.Column('key_returned', sa.Boolean(), nullable=True, server_default='false'))
    op.add_column('check_outs', sa.Column('id_returned', sa.Boolean(), nullable=True, server_default='false'))
    op.add_column('check_outs', sa.Column('feedback_submitted', sa.Boolean(), nullable=True, server_default='false'))
    op.add_column('check_outs', sa.Column('remarks', sa.Text(), nullable=True))
    # rooms: add maintenance_status
    op.add_column('rooms', sa.Column('maintenance_status', sa.String(20), nullable=True, server_default='good'))
    # housekeeping_tasks: inspection + completion + display fields
    op.add_column('housekeeping_tasks', sa.Column('device_id', sa.String(128), nullable=True))
    op.add_column('housekeeping_tasks', sa.Column('completion_notes', sa.Text(), nullable=True))
    op.add_column('housekeeping_tasks', sa.Column('completed_by', sa.String(36), nullable=True))
    op.add_column('housekeeping_tasks', sa.Column('inspected_by', sa.String(36), nullable=True))
    op.add_column('housekeeping_tasks', sa.Column('inspection_result', sa.String(10), nullable=True))
    op.add_column('housekeeping_tasks', sa.Column('inspection_remarks', sa.Text(), nullable=True))
    op.add_column('housekeeping_tasks', sa.Column('inspected_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('housekeeping_tasks', sa.Column('checkout_time', sa.DateTime(timezone=True), nullable=True))
    op.add_column('housekeeping_tasks', sa.Column('guest_name', sa.String(150), nullable=True))
    # maintenance_tickets: missing operational fields
    op.add_column('maintenance_tickets', sa.Column('severity', sa.String(10), nullable=True, server_default='medium'))
    op.add_column('maintenance_tickets', sa.Column('notes', sa.Text(), nullable=True))
    op.add_column('maintenance_tickets', sa.Column('photo_url', sa.Text(), nullable=True))
    op.add_column('maintenance_tickets', sa.Column('repair_cost', sa.Numeric(10, 2), nullable=True))
    op.add_column('maintenance_tickets', sa.Column('created_at_ts', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column('maintenance_tickets', 'created_at_ts')
    op.drop_column('maintenance_tickets', 'repair_cost')
    op.drop_column('maintenance_tickets', 'photo_url')
    op.drop_column('maintenance_tickets', 'notes')
    op.drop_column('maintenance_tickets', 'severity')
    op.drop_column('housekeeping_tasks', 'guest_name')
    op.drop_column('housekeeping_tasks', 'checkout_time')
    op.drop_column('housekeeping_tasks', 'inspected_at')
    op.drop_column('housekeeping_tasks', 'inspection_remarks')
    op.drop_column('housekeeping_tasks', 'inspection_result')
    op.drop_column('housekeeping_tasks', 'inspected_by')
    op.drop_column('housekeeping_tasks', 'completed_by')
    op.drop_column('housekeeping_tasks', 'completion_notes')
    op.drop_column('housekeeping_tasks', 'device_id')
    op.drop_column('rooms', 'maintenance_status')
    op.drop_column('check_outs', 'remarks')
    op.drop_column('check_outs', 'feedback_submitted')
    op.drop_column('check_outs', 'id_returned')
    op.drop_column('check_outs', 'key_returned')
    op.drop_column('check_outs', 'refund_amount')
    op.drop_column('check_outs', 'gst')
    op.drop_column('check_outs', 'discount')
    op.drop_column('check_outs', 'miscellaneous_charges')
    op.drop_column('check_outs', 'damage_charges')
    op.drop_column('check_outs', 'minibar_charges')
    op.drop_column('check_outs', 'laundry_charges')
    op.drop_column('check_outs', 'restaurant_charges')
    op.drop_column('check_outs', 'room_charges')
