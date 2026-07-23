"""merge multiple heads

Revision ID: 8025e8be3b16
Revises: a1b2c3d4e5f6, e6a3c9b7c8d2
Create Date: 2026-07-23 14:50:19.870837

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '8025e8be3b16'
down_revision: Union[str, Sequence[str], None] = ('a1b2c3d4e5f6', 'e6a3c9b7c8d2')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
