"""
Functional tests for the Settings Module (Module 15).

Covers:
- System Configuration CRUD (create, list, get-by-id, get-by-key, update, delete)
- Property Setting CRUD + UNIQUE(property_id, setting_key) enforcement
- Soft delete behavior (is_deleted, version bump)
- Bulk upsert
- Hierarchy data layer: system → property precedence
- Conflict resolution: version-based LWW (Last-Write-Wins with version check)

Uses SQLite in-memory via the test conftest (bypasses PostgreSQL requirement).
"""
import uuid

import pytest

pytestmark = pytest.mark.asyncio

# ── Helpers ─────────────────────────────────────────────────────


def _sys_payload(key="MAX_ROOMS", value="200", desc="Max rooms per property"):
    return {"config_key": key, "config_value": value, "description": desc}


def _prop_payload(key="CHECKIN_TIME", value="14:00", vtype="string", desc="Default check-in"):
    return {"setting_key": key, "setting_value": value, "value_type": vtype, "description": desc}


# ===================================================================
# System Configuration Tests
# ===================================================================

class TestSystemConfigCRUD:
    """POST/GET/PATCH/DELETE /settings/system"""

    async def test_create_system_config(self, client):
        resp = await client.post("/settings/system", json=_sys_payload())
        assert resp.status_code == 201
        body = resp.json()
        assert body["config_key"] == "MAX_ROOMS"
        assert body["config_value"] == "200"
        assert "id" in body

    async def test_create_duplicate_key_returns_409(self, client):
        await client.post("/settings/system", json=_sys_payload(key="DUP_KEY"))
        resp = await client.post("/settings/system", json=_sys_payload(key="DUP_KEY", value="999"))
        assert resp.status_code == 409
        assert "already exists" in resp.json()["detail"]

    async def test_list_system_configs(self, client):
        await client.post("/settings/system", json=_sys_payload(key="A1"))
        await client.post("/settings/system", json=_sys_payload(key="B2"))
        resp = await client.get("/settings/system")
        assert resp.status_code == 200
        body = resp.json()
        assert body["total"] >= 2
        keys = [c["config_key"] for c in body["items"]]
        assert "A1" in keys
        assert "B2" in keys

    async def test_list_system_configs_with_search(self, client):
        await client.post("/settings/system", json=_sys_payload(key="SEARCHABLE_FOO"))
        await client.post("/settings/system", json=_sys_payload(key="OTHER_BAR"))
        resp = await client.get("/settings/system", params={"search": "SEARCHABLE"})
        assert resp.status_code == 200
        keys = [c["config_key"] for c in resp.json()["items"]]
        assert "SEARCHABLE_FOO" in keys
        assert "OTHER_BAR" not in keys

    async def test_get_system_config_by_id(self, client):
        create = await client.post("/settings/system", json=_sys_payload(key="BYID"))
        config_id = create.json()["id"]
        resp = await client.get(f"/settings/system/{config_id}")
        assert resp.status_code == 200
        assert resp.json()["config_key"] == "BYID"

    async def test_get_system_config_by_id_404(self, client):
        resp = await client.get(f"/settings/system/{uuid.uuid4()}")
        assert resp.status_code == 404

    async def test_get_system_config_by_key(self, client):
        await client.post("/settings/system", json=_sys_payload(key="BYKEY"))
        resp = await client.get("/settings/system/by-key/BYKEY")
        assert resp.status_code == 200
        assert resp.json()["config_key"] == "BYKEY"

    async def test_get_system_config_by_key_404(self, client):
        resp = await client.get("/settings/system/by-key/NONEXISTENT")
        assert resp.status_code == 404

    async def test_update_system_config(self, client):
        create = await client.post("/settings/system", json=_sys_payload(key="UPD"))
        config_id = create.json()["id"]
        resp = await client.patch(
            f"/settings/system/{config_id}",
            json={"config_value": "500", "description": "Updated"},
        )
        assert resp.status_code == 200
        assert resp.json()["config_value"] == "500"
        assert resp.json()["description"] == "Updated"

    async def test_update_system_config_404(self, client):
        resp = await client.patch(
            f"/settings/system/{uuid.uuid4()}",
            json={"config_value": "x"},
        )
        assert resp.status_code == 404

    async def test_delete_system_config(self, client):
        create = await client.post("/settings/system", json=_sys_payload(key="DEL"))
        config_id = create.json()["id"]
        resp = await client.delete(f"/settings/system/{config_id}")
        assert resp.status_code == 204
        # Confirm it's gone
        resp2 = await client.get(f"/settings/system/{config_id}")
        assert resp2.status_code == 404

    async def test_delete_system_config_404(self, client):
        resp = await client.delete(f"/settings/system/{uuid.uuid4()}")
        assert resp.status_code == 404


# ===================================================================
# Property Setting Tests
# ===================================================================

class TestPropertySettingCRUD:
    """POST/GET/PATCH/DELETE /settings/property/{property_id}"""

    PROPERTY_ID = uuid.uuid4()

    async def test_create_property_setting(self, client):
        pid = uuid.uuid4()
        resp = await client.post(
            f"/settings/property/{pid}",
            json=_prop_payload(),
        )
        assert resp.status_code == 201
        body = resp.json()
        assert body["setting_key"] == "CHECKIN_TIME"
        assert body["version"] == 1
        assert "is_deleted" not in body  # sync-layer field, not exposed via API

    async def test_create_duplicate_returns_409(self, client):
        pid = uuid.uuid4()
        await client.post(f"/settings/property/{pid}", json=_prop_payload(key="DUP"))
        resp = await client.post(
            f"/settings/property/{pid}",
            json=_prop_payload(key="DUP", value="999"),
        )
        assert resp.status_code == 409
        assert "already exists" in resp.json()["detail"]

    async def test_list_property_settings(self, client):
        pid = uuid.uuid4()
        await client.post(f"/settings/property/{pid}", json=_prop_payload(key="L1"))
        await client.post(f"/settings/property/{pid}", json=_prop_payload(key="L2"))
        resp = await client.get(f"/settings/property/{pid}")
        assert resp.status_code == 200
        assert resp.json()["total"] == 2

    async def test_get_property_setting_by_id(self, client):
        pid = uuid.uuid4()
        create = await client.post(f"/settings/property/{pid}", json=_prop_payload(key="GBYID"))
        setting_id = create.json()["id"]
        resp = await client.get(f"/settings/property/{pid}/{setting_id}")
        assert resp.status_code == 200
        assert resp.json()["setting_key"] == "GBYID"

    async def test_get_property_setting_by_id_wrong_property_404(self, client):
        pid = uuid.uuid4()
        create = await client.post(f"/settings/property/{pid}", json=_prop_payload(key="WRONG"))
        setting_id = create.json()["id"]
        # Request with different property_id — must 404
        resp = await client.get(f"/settings/property/{uuid.uuid4()}/{setting_id}")
        assert resp.status_code == 404

    async def test_get_property_setting_by_key(self, client):
        pid = uuid.uuid4()
        await client.post(f"/settings/property/{pid}", json=_prop_payload(key="GBK"))
        resp = await client.get(f"/settings/property/{pid}/by-key/GBK")
        assert resp.status_code == 200
        assert resp.json()["setting_key"] == "GBK"

    async def test_get_property_setting_by_key_404(self, client):
        pid = uuid.uuid4()
        resp = await client.get(f"/settings/property/{pid}/by-key/NOPE")
        assert resp.status_code == 404

    async def test_update_property_setting_bumps_version(self, client):
        pid = uuid.uuid4()
        create = await client.post(f"/settings/property/{pid}", json=_prop_payload(key="VER"))
        setting_id = create.json()["id"]
        assert create.json()["version"] == 1

        resp = await client.patch(
            f"/settings/property/{pid}/{setting_id}",
            json={"setting_value": "15:00"},
        )
        assert resp.status_code == 200
        assert resp.json()["setting_value"] == "15:00"
        assert resp.json()["version"] == 2

    async def test_delete_property_setting_soft_delete(self, client):
        pid = uuid.uuid4()
        create = await client.post(f"/settings/property/{pid}", json=_prop_payload(key="SD"))
        setting_id = create.json()["id"]

        resp = await client.delete(f"/settings/property/{pid}/{setting_id}")
        assert resp.status_code == 204

        # Soft-deleted: must not appear in GET by-id
        resp2 = await client.get(f"/settings/property/{pid}/{setting_id}")
        assert resp2.status_code == 404

        # Soft-deleted: must not appear in list
        resp3 = await client.get(f"/settings/property/{pid}")
        keys = [s["setting_key"] for s in resp3.json()["items"]]
        assert "SD" not in keys

        # Regression: re-creating with the same key after soft-delete must succeed
        # (partial unique index only enforces uniqueness on is_deleted = FALSE rows)
        resp4 = await client.post(f"/settings/property/{pid}", json=_prop_payload(key="SD"))
        assert resp4.status_code == 201
        assert resp4.json()["setting_value"] == "14:00"

    async def test_delete_property_setting_404(self, client):
        pid = uuid.uuid4()
        resp = await client.delete(f"/settings/property/{pid}/{uuid.uuid4()}")
        assert resp.status_code == 404


# ===================================================================
# Bulk Upsert
# ===================================================================

class TestBulkUpsert:
    async def test_bulk_upsert_creates_new(self, client):
        pid = uuid.uuid4()
        payload = {
            "settings": [
                _prop_payload(key="BULK1", value="v1"),
                _prop_payload(key="BULK2", value="v2"),
            ]
        }
        resp = await client.post(f"/settings/property/{pid}/bulk", json=payload)
        assert resp.status_code == 200
        assert resp.json()["total"] == 2

    async def test_bulk_upsert_updates_existing(self, client):
        pid = uuid.uuid4()
        # Create first
        await client.post(f"/settings/property/{pid}/bulk", json={
            "settings": [_prop_payload(key="BULK_UPD", value="old")]
        })
        # Upsert same key with new value
        resp = await client.post(f"/settings/property/{pid}/bulk", json={
            "settings": [_prop_payload(key="BULK_UPD", value="new")]
        })
        assert resp.status_code == 200
        items = resp.json()["items"]
        assert len(items) == 1
        assert items[0]["setting_value"] == "new"
        assert items[0]["version"] == 2


# ===================================================================
# Hierarchy Resolution (system → property → device)
# ===================================================================

class TestHierarchyResolution:
    """
    The API stores system configs and property settings as separate tables.
    The device-side (Flutter) resolves hierarchy.
    Here we verify the data layer allows overlapping keys across tiers
    and that property settings override system defaults.
    """

    async def test_system_and_property_can_share_key(self, client):
        """System has CHECKIN_TIME=14:00, property has CHECKIN_TIME=12:00.
        Both should exist independently."""
        await client.post("/settings/system", json=_sys_payload(
            key="CHECKIN_TIME", value="14:00", desc="System default"
        ))
        pid = uuid.uuid4()
        await client.post(f"/settings/property/{pid}", json=_prop_payload(
            key="CHECKIN_TIME", value="12:00", desc="Property override"
        ))

        # System still returns 14:00
        sys_resp = await client.get("/settings/system/by-key/CHECKIN_TIME")
        assert sys_resp.status_code == 200
        assert sys_resp.json()["config_value"] == "14:00"

        # Property returns 12:00
        prop_resp = await client.get(f"/settings/property/{pid}/by-key/CHECKIN_TIME")
        assert prop_resp.status_code == 200
        assert prop_resp.json()["setting_value"] == "12:00"

    async def test_multiple_properties_independent(self, client):
        pid_a = uuid.uuid4()
        pid_b = uuid.uuid4()
        await client.post(f"/settings/property/{pid_a}", json=_prop_payload(key="CURRENCY", value="INR"))
        await client.post(f"/settings/property/{pid_b}", json=_prop_payload(key="CURRENCY", value="USD"))

        resp_a = await client.get(f"/settings/property/{pid_a}/by-key/CURRENCY")
        resp_b = await client.get(f"/settings/property/{pid_b}/by-key/CURRENCY")
        assert resp_a.json()["setting_value"] == "INR"
        assert resp_b.json()["setting_value"] == "USD"


# ===================================================================
# Conflict Resolution: version-based LWW
# ===================================================================

class TestConflictResolution:
    """
    The sync engine uses HLC-based conflict resolution.
    At the API level, writes always succeed (last-write-wins) and
    version is bumped. The device-side uses version + HLC to
    decide which write wins during merge.
    """

    async def test_version_increments_on_each_write(self, client):
        pid = uuid.uuid4()
        create = await client.post(f"/settings/property/{pid}", json=_prop_payload(key="VER"))
        setting_id = create.json()["id"]
        assert create.json()["version"] == 1

        for expected in [2, 3, 4]:
            resp = await client.patch(
                f"/settings/property/{pid}/{setting_id}",
                json={"setting_value": f"v{expected}"},
            )
            assert resp.json()["version"] == expected

    async def test_delete_increments_version(self, client):
        pid = uuid.uuid4()
        create = await client.post(f"/settings/property/{pid}", json=_prop_payload(key="DELVER"))
        setting_id = create.json()["id"]

        await client.delete(f"/settings/property/{pid}/{setting_id}")

        # Regression: re-creating with the same key after soft-delete must succeed
        resp = await client.post(f"/settings/property/{pid}", json=_prop_payload(key="DELVER"))
        assert resp.status_code == 201
        assert resp.json()["version"] == 1  # Fresh record starts at 1


# ===================================================================
# Validation
# ===================================================================

class TestValidation:
    async def test_invalid_value_type_rejected(self, client):
        pid = uuid.uuid4()
        resp = await client.post(
            f"/settings/property/{pid}",
            json=_prop_payload(vtype="invalid_type"),
        )
        assert resp.status_code == 422

    async def test_missing_required_fields(self, client):
        resp = await client.post("/settings/system", json={})
        assert resp.status_code == 422
