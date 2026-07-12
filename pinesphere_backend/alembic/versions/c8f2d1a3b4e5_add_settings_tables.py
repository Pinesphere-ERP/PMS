"""Add settings tables: system_configurations, property_settings

Revision ID: c8f2d1a3b4e5
Revises: 5b407ba6ca21
Create Date: 2026-07-10 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID as PGUUID, JSONB

revision = "c8f2d1a3b4e5"
down_revision = "5b407ba6ca21"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── system_configurations ──────────────────────────────────
    op.create_table(
        "system_configurations",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True),
        sa.Column("config_key", sa.String(100), nullable=False, unique=True, index=True),
        sa.Column("config_value", sa.Text, nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("updated_by", PGUUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )

    # ── property_settings ──────────────────────────────────────
    op.create_table(
        "property_settings",
        sa.Column("id", PGUUID(as_uuid=True), primary_key=True),
        sa.Column(
            "property_id", PGUUID(as_uuid=True),
            sa.ForeignKey("properties.property_id", ondelete="CASCADE"),
            nullable=False, index=True,
        ),
        sa.Column("setting_key", sa.String(100), nullable=False),
        sa.Column("setting_value", sa.Text, nullable=False),
        sa.Column("value_type", sa.String(20), nullable=False, server_default="string"),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("updated_by", PGUUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("version", sa.Integer, nullable=False, server_default="1"),
        sa.Column("is_deleted", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("device_id", sa.String(128), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.UniqueConstraint("property_id", "setting_key", name="uq_property_settings_property_key"),
    )


def downgrade() -> None:
    op.drop_table("property_settings")
    op.drop_table("system_configurations")
