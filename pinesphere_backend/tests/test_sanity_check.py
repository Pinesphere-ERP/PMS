"""
Isolation sanity check: proves that app.infra.models.SystemConfiguration
is the REAL class (with PGUUID column type), NOT the SQLite-compatible
test copy — even when settings tests have run in the same pytest process.

This test does NOT request the patched_settings_models fixture, so
monkeypatch never patches app.infra.models during its execution.
"""
from sqlalchemy.dialects.postgresql import UUID as PGUUID


def test_system_configuration_has_real_pguuid():
    """If the monkey-patch from conftest leaked, id column would be
    GUIDString (VARCHAR 36), not PGUUID."""
    from app.infra.models import SystemConfiguration

    id_column = SystemConfiguration.id
    # The real model uses PGUUID(as_uuid=True); the test copy uses GUIDString
    assert isinstance(id_column.type, PGUUID), (
        f"Expected PGUUID, got {type(id_column.type).__name__}. "
        "The settings monkey-patch has leaked into this test."
    )


def test_property_setting_has_real_pguuid():
    from app.infra.models import PropertySetting

    id_column = PropertySetting.id
    assert isinstance(id_column.type, PGUUID), (
        f"Expected PGUUID, got {type(id_column.type).__name__}. "
        "The settings monkey-patch has leaked into this test."
    )
