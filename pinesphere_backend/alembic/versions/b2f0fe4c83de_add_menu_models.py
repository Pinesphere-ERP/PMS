"""Add Menu Models

Revision ID: b2f0fe4c83de
Revises: 54518110c55c
Create Date: 2026-07-21 18:43:09.182406

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'b2f0fe4c83de'
down_revision: Union[str, Sequence[str], None] = '54518110c55c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('menu_categories',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('property_id', sa.UUID(), nullable=False),
    sa.Column('name', sa.String(length=100), nullable=False),
    sa.Column('description', sa.String(length=255), nullable=True),
    sa.Column('sort_order', sa.Integer(), nullable=False),
    sa.Column('is_active', sa.Boolean(), nullable=False),
    sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.Column('last_modified_hlc', sa.String(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('deleted_at', sa.DateTime(), nullable=True),
    sa.Column('device_id', sa.String(), nullable=True),
    sa.ForeignKeyConstraint(['property_id'], ['properties.property_id'], name=op.f('fk_menu_categories_property_id_properties'), ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name=op.f('pk_menu_categories'))
    )
    op.create_index(op.f('ix_menu_categories_last_modified_hlc'), 'menu_categories', ['last_modified_hlc'], unique=False)
    
    op.create_table('menu_items',
    sa.Column('id', sa.UUID(), nullable=False),
    sa.Column('category_id', sa.UUID(), nullable=False),
    sa.Column('property_id', sa.UUID(), nullable=False),
    sa.Column('name', sa.String(length=150), nullable=False),
    sa.Column('description', sa.Text(), nullable=True),
    sa.Column('price', sa.Numeric(precision=10, scale=2), nullable=False),
    sa.Column('veg_type', sa.String(length=20), nullable=False),
    sa.Column('is_available', sa.Boolean(), nullable=False),
    sa.Column('image_url', sa.String(length=500), nullable=True),
    sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    sa.Column('last_modified_hlc', sa.String(), nullable=False),
    sa.Column('is_deleted', sa.Boolean(), nullable=False),
    sa.Column('deleted_at', sa.DateTime(), nullable=True),
    sa.Column('device_id', sa.String(), nullable=True),
    sa.ForeignKeyConstraint(['category_id'], ['menu_categories.id'], name=op.f('fk_menu_items_category_id_menu_categories'), ondelete='CASCADE'),
    sa.ForeignKeyConstraint(['property_id'], ['properties.property_id'], name=op.f('fk_menu_items_property_id_properties'), ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name=op.f('pk_menu_items'))
    )
    op.create_index(op.f('ix_menu_items_last_modified_hlc'), 'menu_items', ['last_modified_hlc'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_menu_items_last_modified_hlc'), table_name='menu_items')
    op.drop_table('menu_items')
    op.drop_index(op.f('ix_menu_categories_last_modified_hlc'), table_name='menu_categories')
    op.drop_table('menu_categories')
