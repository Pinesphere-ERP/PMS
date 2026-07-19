"""add subscription_required

Revision ID: 5b62b145a1c1
Revises: 3910aebb8b5e
Create Date: 2026-07-15 15:43:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '5b62b145a1c1'
down_revision = '3910aebb8b5e'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    if 'subscriptions' in inspector.get_table_names(schema='public'):
        columns = [col['name'] for col in inspector.get_columns('subscriptions', schema='public')]
        if 'subscription_required' in columns:
            print("subscription_required column already exists, skipping.")
            return

    op.add_column('subscriptions', sa.Column('subscription_required', sa.Boolean(), server_default='true', nullable=False))


def downgrade() -> None:
    op.drop_column('subscriptions', 'subscription_required')
