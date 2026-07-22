# 10. Sync Engine

## Overview

The sync engine enables the mobile app to operate **fully offline** and synchronize with the backend when connectivity is restored.

It consists of:
1. **Backend sync endpoints** — `POST /sync/push` and `POST /sync/pull`
2. **ObjectBox local database** — stores all entity data on device
3. **OfflineOutboxInterceptor** — queues failed API calls to ObjectBox
4. **SyncEngine** (Flutter) — orchestrates push/pull operations
5. **WorkManager** — runs background sync on a 15-minute schedule

---

## Architecture

```
Flutter App
    |
    |--> User creates a booking (offline)
    |        |
    |        v
    |    Dio POST /bookings fails (no internet)
    |        |
    |        v
    |    OfflineOutboxInterceptor saves to ObjectBox:
    |        SyncOperation {
    |            entityType: "Booking",
    |            entityId: "uuid",
    |            operationType: "create",
    |            payload: { ... all booking fields ... },
    |            createdAt: DateTime.now()
    |        }
    |        |
    |        v
    |    UI receives fake 202 response (appears successful)
    |
    |--> Connectivity restored (or WorkManager fires)
    |        |
    |        v
    |    SyncEngine.push() reads all SyncOperations from ObjectBox
    |        |
    |        v
    |    POST /sync/push with batch of records
    |        |
    |        v
    |    Backend processes each record:
    |        - Validates entity type (whitelist)
    |        - Validates property ownership
    |        - Validates timestamp (no future timestamps)
    |        - INSERT or UPDATE record (last-writer-wins by HLC)
    |        |
    |        v
    |    Response: { accepted_ids, conflicts, failed_ids }
    |        |
    |        v
    |    SyncEngine removes accepted operations from ObjectBox
    |        |
    |        v
    |    SyncEngine.pull() fetches updates from server:
    |    POST /sync/pull { since_timestamp: last_sync_at }
    |        |
    |        v
    |    Backend returns all records modified since last_sync_at
    |        |
    |        v
    |    SyncEngine merges records into ObjectBox
```

---

## SyncOperation Model (ObjectBox)

```dart
@Entity()
class SyncOperation {
  @Id()
  int id = 0;
  
  String entityType;      // "Booking", "Room", "Guest", etc.
  String entityId;        // UUID of the entity
  String operationType;   // "create", "update", "delete"
  String payload;         // JSON-encoded entity data
  DateTime createdAt;
  int retryCount = 0;
  String? errorMessage;
}
```

---

## Backend: POST /sync/push

**File:** `pinesphere_backend/app/modules/sync/service.py`

### Validation Pipeline

For each record in the batch:

1. **Entity Type Whitelist:**
   ```
   Allowed: Room, RoomCategory, Guest, Booking,
            CheckIn, CheckOut, Payment, 
            HousekeepingTask, MaintenanceTicket,
            Task, TaskLog, User, Role, RolePermission
   ```
   Any other entity type is rejected into `failed_ids`.

2. **Property Ownership:**
   - If the model has a `property_id` field, the payload's `property_id` must match the request's `property_id`.
   - Prevents cross-property data injection attacks.

3. **Timestamp Validation:**
   - `updated_at` must not be more than 5 minutes in the future.
   - Prevents timestamp manipulation.

4. **Conflict Resolution:**
   - If a record exists in DB with a newer `updated_at` than the incoming record, it's reported as a **conflict** (not an error).
   - The backend version wins (server-authoritative).
   - Conflicts are returned to the client so it can re-download the server version.

5. **Insert or Update:**
   - If record exists: `UPDATE` with payload fields.
   - If record does not exist: `INSERT` with payload.

### Push Request Schema

```json
{
  "property_id": "uuid",
  "records": [
    {
      "entity_type": "Booking",
      "entity_id": "uuid",
      "operation": "create",
      "payload": {
        "booking_id": "uuid",
        "property_id": "uuid",
        "room_id": "uuid",
        "guest_id": "uuid",
        "check_in_date": "2026-07-25",
        "check_out_date": "2026-07-28",
        ...
      },
      "updated_at": "2026-07-22T10:00:00Z"
    }
  ]
}
```

### Push Response Schema

```json
{
  "accepted_ids": ["uuid1", "uuid2"],
  "conflicts": [
    {
      "entity_id": "uuid3",
      "reason": "Server has newer version",
      "server_updated_at": "2026-07-22T11:00:00Z"
    }
  ],
  "failed_ids": ["uuid4"]
}
```

---

## Backend: POST /sync/pull

Fetches all records modified since a given timestamp.

### Pull Request Schema

```json
{
  "property_id": "uuid",
  "since_timestamp": "2026-07-22T00:00:00Z",
  "entity_types": ["Booking", "Room", "Guest"]
}
```

### Pull Response Schema

```json
{
  "records": [
    {
      "entity_type": "Room",
      "entity_id": "uuid",
      "payload": { ... },
      "updated_at": "2026-07-22T10:30:00Z",
      "operation": "update"
    }
  ],
  "server_timestamp": "2026-07-22T14:00:00Z"
}
```

The client stores `server_timestamp` and uses it as `since_timestamp` in the next pull.

---

## HLC (Hybrid Logical Clock)

The `last_modified_hlc` field on SyncMixin models provides strict ordering:

**Format:** `<unix_ms>-<logical_counter>-<node_id>`

**Example:** `1721649600000-001-device123`

**Purpose:**
- Physical component (`unix_ms`) gives approximate ordering.
- Logical counter disambiguates events at the same millisecond.
- Node ID (device fingerprint) makes the clock globally unique.

**Why HLC instead of simple timestamp?**
- Clock skew: Different devices may have clocks off by minutes.
- Without HLC, a device with a future clock would always "win" conflicts.
- With HLC, the system converges to correct ordering despite clock drift.

---

## Soft Deletes

The `SyncMixin` includes:
```
is_deleted: bool = false
deleted_at: datetime | None
```

Records are **never physically deleted** from the mobile ObjectBox store. Instead:
- `is_deleted = true` marks deletion.
- The sync engine propagates deletions as `operation: "delete"` records.
- Backend sets `is_deleted = true` on sync push.
- Pull requests include soft-deleted records so clients can remove them locally.

**Why not hard delete?**
- Hard deletes create sync "amnesia" — clients that sync later have no way to know a record was deleted.
- Soft deletes allow the deletion event to propagate to all clients.

---

## WorkManager Background Sync

**Package:** `workmanager` (Flutter)

**Configuration:**
```dart
Workmanager().registerPeriodicTask(
  "sync_task",
  "background_sync",
  frequency: Duration(minutes: 15),
  constraints: Constraints(
    networkType: NetworkType.connected,
  ),
);
```

**Background sync flow:**
1. Check connectivity.
2. Push pending SyncOperations.
3. Pull server changes.
4. Update `last_sync_at` timestamp.
5. Show sync notification (if any errors).

---

## Conflict Resolution Strategy

**Strategy:** Last-writer-wins with server authority on conflicts.

| Scenario | Resolution |
|----------|-----------|
| Client creates record not in server | Server inserts it |
| Client updates older server record | Server updates it |
| Client updates newer server record | Server rejects (conflict), client re-downloads |
| Two clients update same record simultaneously | The one that syncs first wins; other is re-downloaded |
| Client deletes, server updated | Server version preserved, client re-downloads |

**Future enhancement:** Field-level CRDT (Conflict-free Replicated Data Types) for more granular merging.

---

## Sync Security

- Sync push is authenticated — requires Bearer JWT.
- `property_id` in sync push is validated against the authenticated user's property.
- Entity type whitelist prevents arbitrary table writes.
- Timestamp validation prevents future-dated attacks.
- Cross-property write attempts are logged as security incidents.

---

## Known Limitations

1. **No delta fields** — push syncs entire entity payloads, not just changed fields.
2. **No real-time sync** — sync is periodic (every 15 min) or manual. No WebSocket.
3. **Token refresh not implemented** — if the access token expires during offline period, sync will fail with 401.
4. **Large payloads** — no batching size limit enforced. Very large sync pushes may time out on Render free tier.

---

## Cross-References

- ObjectBox models: [08-mobile.md](./08-mobile.md)
- Backend sync module: [05-backend.md](./05-backend.md)
- Authentication: [09-auth-security.md](./09-auth-security.md)
