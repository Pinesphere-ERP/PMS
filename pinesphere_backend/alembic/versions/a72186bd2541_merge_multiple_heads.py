"""Merge multiple heads

Revision ID: a72186bd2541
Revises: c55e83a79a0a, fe2bb955f4fc
Create Date: 2026-07-12 16:34:03.154634

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a72186bd2541'
down_revision: Union[str, Sequence[str], None] = ('c55e83a79a0a', 'fe2bb955f4fc')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
