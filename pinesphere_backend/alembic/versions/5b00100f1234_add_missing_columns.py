"""add_missing_columns

Revision ID: 5b00100f1234
Revises: 4a994f783051
Create Date: 2026-07-13 13:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5b00100f1234'
down_revision: Union[str, Sequence[str], None] = '4a994f783051'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add updated_at to role_permissions
    op.add_column('role_permissions', sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True))
    
    # Drop remarks from invoice_items if it exists, wait, we can just skip dropping to be safe
    # Or do it safely with raw SQL if needed, but dropping isn't breaking the app usually, 
    # it's the missing columns that break it.
    pass


def downgrade() -> None:
    op.drop_column('users', 'device_fingerprint')
    op.drop_column('role_permissions', 'updated_at')
