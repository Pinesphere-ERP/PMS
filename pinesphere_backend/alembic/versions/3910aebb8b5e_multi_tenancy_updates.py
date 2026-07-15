"""multi-tenancy updates

Revision ID: 3910aebb8b5e
Revises: 4a994f783051
Create Date: 2026-07-15 14:07:57.717806

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3910aebb8b5e'
down_revision: Union[str, Sequence[str], None] = '4a994f783051'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


from sqlalchemy.dialects import postgresql

def upgrade() -> None:
    # 1. Create user_property_access table
    op.create_table('user_property_access',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('property_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('role_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['property_id'], ['properties.property_id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['role_id'], ['roles.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'property_id', name='uq_user_property_access')
    )
    
    # 2. Update users unique constraints
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS uq_users_property_mobile")
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS uq_users_property_username")
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_mobile_number_key")
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS users_username_key")
    op.create_unique_constraint('uq_users_mobile_number', 'users', ['mobile_number'])
    op.create_unique_constraint('uq_users_username', 'users', ['username'])
    
    # 3. Add property_id to guests (nullable first, then we could backfill, but for now just add it)
    op.add_column('guests', sa.Column('property_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.create_foreign_key(None, 'guests', 'properties', ['property_id'], ['property_id'], ondelete='CASCADE')
    
    # 4. Add property_id to rooms
    op.add_column('rooms', sa.Column('property_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.create_foreign_key(None, 'rooms', 'properties', ['property_id'], ['property_id'], ondelete='CASCADE')


def downgrade() -> None:
    # 4. Remove from rooms
    op.drop_constraint(None, 'rooms', type_='foreignkey')
    op.drop_column('rooms', 'property_id')
    
    # 3. Remove from guests
    op.drop_constraint(None, 'guests', type_='foreignkey')
    op.drop_column('guests', 'property_id')
    
    # 2. Revert unique constraints (safe approach)
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS uq_users_mobile_number")
    op.execute("ALTER TABLE users DROP CONSTRAINT IF EXISTS uq_users_username")
    try:
        op.create_unique_constraint('uq_users_property_mobile', 'users', ['property_id', 'mobile_number'])
        op.create_unique_constraint('uq_users_property_username', 'users', ['property_id', 'username'])
    except Exception:
        pass
    
    # 1. Drop user_property_access
    op.drop_table('user_property_access')
