"""Restore missing production migration

Revision ID: e4423c8030af
Revises: c9b7e813a94c
Create Date: 2026-07-21 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e4423c8030af'
down_revision: Union[str, Sequence[str], None] = 'c9b7e813a94c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
