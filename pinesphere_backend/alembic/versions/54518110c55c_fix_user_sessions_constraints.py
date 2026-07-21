"""Fix user_sessions constraints

Revision ID: 54518110c55c
Revises: c9b7e813a94c
Create Date: 2026-07-20 09:33:20.000773

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '54518110c55c'
down_revision: Union[str, Sequence[str], None] = 'e4423c8030af'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Alter session_token length to 500
    op.alter_column('user_sessions', 'session_token',
               existing_type=sa.String(length=255),
               type_=sa.String(length=500),
               existing_nullable=False,
               schema='public')
               
    # Make device_id nullable
    op.alter_column('user_sessions', 'device_id',
               existing_type=sa.UUID(),
               nullable=True,
               existing_nullable=False,
               schema='public')


def downgrade() -> None:
    # Revert device_id nullable
    op.alter_column('user_sessions', 'device_id',
               existing_type=sa.UUID(),
               nullable=False,
               existing_nullable=True,
               schema='public')
               
    # Revert session_token length
    op.alter_column('user_sessions', 'session_token',
               existing_type=sa.String(length=500),
               type_=sa.String(length=255),
               existing_nullable=False,
               schema='public')
