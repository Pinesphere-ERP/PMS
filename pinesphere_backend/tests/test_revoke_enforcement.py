"""
Tests that the pinesphere_app role is correctly REVOKEd from mutating audit_logs.

These tests connect to the real PostgreSQL database as the pinesphere_app role
(the actual role the FastAPI app connects as) and verify:
  - INSERT into audit_logs: allowed
  - SELECT from audit_logs: allowed
  - UPDATE on audit_logs: rejected (permission denied)
  - DELETE from audit_logs: rejected (permission denied)
  - TRUNCATE audit_logs: rejected (permission denied via REVOKE, trigger is backup)

Requires: a running PostgreSQL instance with pinesphere_app role created
by the c3d4e5f6a7b8 migration. Skipped if the database is unreachable.
"""
import uuid

import pytest
import psycopg2
import psycopg2.errors

APP_DB_URL = "postgresql://pinesphere_app:pinesphere_password@localhost:5444/pinesphere"
ADMIN_DB_URL = "postgresql://pinesphere:pinesphere_password@localhost:5444/pinesphere"


def _get_app_connection():
    return psycopg2.connect(APP_DB_URL)


def _get_admin_connection():
    return psycopg2.connect(ADMIN_DB_URL)


def _database_reachable():
    try:
        conn = _get_admin_connection()
        conn.close()
        return True
    except Exception:
        return False


pytestmark = pytest.mark.skipif(
    not _database_reachable(),
    reason="PostgreSQL not reachable — skipping REVOKE enforcement tests",
)


class TestRevokeEnforcement:
    """Prove the security guarantee holds on the real database."""

    @pytest.fixture(autouse=True)
    def cleanup_test_rows(self):
        """Delete any test rows after each test."""
        yield
        try:
            conn = _get_admin_connection()
            conn.autocommit = True
            cur = conn.cursor()
            cur.execute(
                "DELETE FROM audit_logs WHERE module_name = 'test'"
            )
            cur.close()
            conn.close()
        except Exception:
            pass

    def test_insert_allowed(self):
        """App role CAN insert into audit_logs."""
        conn = _get_app_connection()
        conn.autocommit = True
        cur = conn.cursor()
        test_id = uuid.uuid4()
        target_id = uuid.uuid4()
        try:
            cur.execute(
                "INSERT INTO audit_logs (log_id, timestamp, module_name, action_type, target_entity, target_record_id, entry_hash) "
                "VALUES (%s, now(), 'test', 'test_insert', 'test_entity', %s, 'test_hash')",
                (str(test_id), str(target_id)),
            )
        finally:
            cur.close()
            conn.close()

    def test_select_allowed(self):
        """App role CAN select from audit_logs."""
        conn = _get_app_connection()
        conn.autocommit = True
        cur = conn.cursor()
        try:
            cur.execute("SELECT count(*) FROM audit_logs")
            count = cur.fetchone()[0]
            assert isinstance(count, int)
        finally:
            cur.close()
            conn.close()

    def test_update_rejected(self):
        """App role CANNOT update audit_logs — Postgres must reject with permission denied."""
        conn_admin = _get_admin_connection()
        conn_admin.autocommit = True
        cur_admin = conn_admin.cursor()
        test_id = uuid.uuid4()
        target_id = uuid.uuid4()
        cur_admin.execute(
            "INSERT INTO audit_logs (log_id, timestamp, module_name, action_type, target_entity, target_record_id, entry_hash) "
            "VALUES (%s, now(), 'test', 'setup', 'test_entity', %s, 'hash')",
            (str(test_id), str(target_id)),
        )
        cur_admin.close()
        conn_admin.close()

        conn = _get_app_connection()
        conn.autocommit = True
        cur = conn.cursor()
        try:
            with pytest.raises(psycopg2.errors.InsufficientPrivilege):
                cur.execute("UPDATE audit_logs SET action_type = 'TAMPERED' WHERE log_id = %s", (str(test_id),))
        finally:
            cur.close()
            conn.close()

    def test_delete_rejected(self):
        """App role CANNOT delete from audit_logs — Postgres must reject with permission denied."""
        conn_admin = _get_admin_connection()
        conn_admin.autocommit = True
        cur_admin = conn_admin.cursor()
        test_id = uuid.uuid4()
        target_id = uuid.uuid4()
        cur_admin.execute(
            "INSERT INTO audit_logs (log_id, timestamp, module_name, action_type, target_entity, target_record_id, entry_hash) "
            "VALUES (%s, now(), 'test', 'setup', 'test_entity', %s, 'hash')",
            (str(test_id), str(target_id)),
        )
        cur_admin.close()
        conn_admin.close()

        conn = _get_app_connection()
        conn.autocommit = True
        cur = conn.cursor()
        try:
            with pytest.raises(psycopg2.errors.InsufficientPrivilege):
                cur.execute("DELETE FROM audit_logs WHERE log_id = %s", (str(test_id),))
        finally:
            cur.close()
            conn.close()

    def test_truncate_rejected(self):
        """App role CANNOT truncate audit_logs — REVOKE fires first, trigger is backup."""
        conn = _get_app_connection()
        conn.autocommit = True
        cur = conn.cursor()
        try:
            with pytest.raises(psycopg2.errors.InsufficientPrivilege):
                cur.execute("TRUNCATE audit_logs")
        finally:
            cur.close()
            conn.close()

    def test_other_tables_unaffected(self):
        """REVOKE is scoped to audit_logs — other tables remain fully accessible."""
        conn = _get_app_connection()
        conn.autocommit = True
        cur = conn.cursor()
        try:
            cur.execute("SELECT count(*) FROM users")
            cur.execute("SELECT count(*) FROM rooms")
            cur.execute("SELECT count(*) FROM bookings")
        finally:
            cur.close()
            conn.close()
