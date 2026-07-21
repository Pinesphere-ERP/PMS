"""Add GuestFeedback model

Revision ID: e4423c8030af
Revises: b2f0fe4c83de
Create Date: 2026-07-21 18:57:08.587910

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'e4423c8030af'
down_revision: Union[str, Sequence[str], None] = 'b2f0fe4c83de'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('guest_feedback',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('property_id', sa.UUID(), nullable=False),
    sa.Column('booking_id', sa.UUID(), nullable=False),
    sa.Column('guest_id', sa.UUID(), nullable=True),
    sa.Column('task_id', sa.UUID(), nullable=True),
    sa.Column('overall_rating', sa.Integer(), nullable=True),
    sa.Column('food_rating', sa.Integer(), nullable=True),
    sa.Column('service_rating', sa.Integer(), nullable=True),
    sa.Column('staff_rating', sa.Integer(), nullable=True),
    sa.Column('comments', sa.Text(), nullable=True),
    sa.Column('is_anonymous', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.Column('last_modified_hlc', sa.String(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('deleted_at', sa.DateTime(), nullable=True),
    sa.Column('device_id', sa.String(), nullable=True),
    sa.ForeignKeyConstraint(['booking_id'], ['bookings.booking_id'], name=op.f('fk_guest_feedback_booking_id_bookings'), ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['guest_id'], ['guests.guest_id'], name=op.f('fk_guest_feedback_guest_id_guests'), ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['property_id'], ['properties.property_id'], name=op.f('fk_guest_feedback_property_id_properties'), ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['task_id'], ['tasks.task_id'], name=op.f('fk_guest_feedback_task_id_tasks'), ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name=op.f('pk_guest_feedback'))
    )
    op.create_index(op.f('ix_guest_feedback_last_modified_hlc'), 'guest_feedback', ['last_modified_hlc'], unique=False)

def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_guest_feedback_last_modified_hlc'), table_name='guest_feedback')
    op.drop_table('guest_feedback')
