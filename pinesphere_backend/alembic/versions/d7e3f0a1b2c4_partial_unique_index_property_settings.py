"""Replace plain UNIQUE(property_id, setting_key) with a partial unique index
scoped to active (non-deleted) rows only.

This fixes a bug where soft-deleted property_settings rows still occupied the
UNIQUE constraint, preventing re-creation of a setting with the same key after
deletion — a normal usage pattern.

Revision ID: d7e3f0a1b2c4
Revises: c8f2d1a3b4e5
Create Date: 2026-07-10 01:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

revision = "d7e3f0a1b2c4"
down_revision = "c8f2d1a3b4e5"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Drop the plain UNIQUE constraint that blocks re-creation after soft-delete
    op.drop_constraint(
        "uq_property_settings_property_key",
        "property_settings",
        type_="unique",
    )

    # Create a partial unique index: only active (non-deleted) rows are unique.
    # Soft-deleted rows with the same (property_id, setting_key) can coexist,
    # allowing delete-then-recreate workflows.
    op.create_index(
        "uq_property_settings_active_key",
        "property_settings",
        ["property_id", "setting_key"],
        unique=True,
        postgresql_where=sa.text("is_deleted = FALSE"),
    )


def downgrade() -> None:
    op.drop_index(
        "uq_property_settings_active_key",
        table_name="property_settings",
    )
    op.create_unique_constraint(
        "uq_property_settings_property_key",
        "property_settings",
        ["property_id", "setting_key"],
    )
    # NOTE: Downgrading re-introduces the soft-delete/unique bug being fixed
    # here. This is expected — the downgrade restores the original schema
    # which had this known limitation.
