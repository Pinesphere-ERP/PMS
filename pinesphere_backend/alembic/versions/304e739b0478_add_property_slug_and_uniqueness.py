"""add property slug and uniqueness

Revision ID: 304e739b0478
Revises: 54518110c55c
Create Date: 2026-07-23 14:10:55.573806

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '304e739b0478'
down_revision: Union[str, Sequence[str], None] = '54518110c55c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('properties', sa.Column('slug', sa.String(length=100), nullable=True))
    op.create_index(op.f('ix_properties_slug'), 'properties', ['slug'], unique=True)
    op.create_unique_constraint('uq_properties_slug', 'properties', ['slug'])


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint('uq_properties_slug', 'properties', type_='unique')
    op.drop_index(op.f('ix_properties_slug'), table_name='properties')
    op.drop_column('properties', 'slug')
