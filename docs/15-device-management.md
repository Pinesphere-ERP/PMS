# 15. Device Management

## Overview

Device management controls which physical tablets and phones are authorized to access the PMS. Every device must be registered and approved before it can use the API.

---

## Device Model

```python
class Device:
    id: UUID
    device_uid: str       # Unique fingerprint (hardware ID)
    property_id: UUID     # Which property this device belongs to
    primary_user_id: UUID # Who primarily uses this device
    device_name: str      # "Lobby Tablet", "Reception PC"
    os_type: str          # android, ios, windows
    status: str           # pending_approval, approved, active, revoked
```

---

## Device Lifecycle

```
[App Installed]
      |
      v
[Device Registers] -- POST /devices/register
      |
      v
[Status: pending_approval]
      |
      v
[Super Admin Reviews] -- GET /devices/global
      |
      v
[Approve] -- PATCH /devices/{id}/approve
      |
      v
[Status: approved]
      |
      v
[First Login] -- sets status: active
      |
      v
[In Use]
      |
      v
[Revoke] -- PATCH /devices/{id}/revoke
      |
      v
[Status: revoked] -- cannot log in, JWT rejected
```

---

## Device Registration

When a new device first runs the app:

1. **Fingerprint generated** on device:
   - Android: Unique ID from `Settings.Secure.ANDROID_ID`
   - iOS: `identifierForVendor`
   - Combined with installation UUID for uniqueness

2. **POST /devices/register**:
   ```json
   {
     "device_uid": "generated-fingerprint",
     "property_id": "uuid",
     "device_name": "Lobby Tablet",
     "os_type": "android"
   }
   ```

3. Device created with `status = "pending_approval"`.

4. Super Admin sees pending device in `/devices/global`.

5. Super Admin approves or rejects.

---

## Device Fingerprint in JWT

Every JWT embeds the `device_fp` (device fingerprint):
```json
{
  "sub": "user-uuid",
  "device_fp": "abc123-device-fingerprint"
}
```

On every API call, `get_current_user()` verifies:
1. `device_fp` matches a registered device in the `devices` table.
2. Device status is `approved` or `active`.
3. Device is not in `device_blacklist`.

This means:
- If a device is revoked, all its active sessions are invalidated immediately.
- A stolen token cannot be used from a different device.

---

## Device Limit

Each property subscription has a `device_limit` (default: 5).

When registering a new device:
```python
subscription = get_subscription(property_id)
if subscription.registered_devices >= subscription.device_limit:
    raise HTTP 403 "Device limit reached"
```

On approval: `subscription.registered_devices += 1`  
On revocation: `subscription.registered_devices -= 1`

---

## Global Device Console (Admin Portal)

**Route:** `/devices/global`  
**File:** `src/pages/DeviceManagement/GlobalDeviceConsole.jsx`

**API:** `GET /devices/global`

**Displays:**
- All devices across all properties
- Filter by status (pending, approved, revoked)
- Filter by property
- Search by device name or fingerprint

**Actions:**
- Approve device (pending -> approved)
- Revoke device (active -> revoked)
- Blacklist device (adds to `device_blacklist` + revokes)

---

## Device Blacklist

A device can be blacklisted when:
- Device is reported stolen
- Suspicious activity detected
- Old/decommissioned device

**Blacklist table:** `device_blacklist`
```python
class DeviceBlacklist:
    device_uid: str       # Fingerprint
    reason: str           # Why blacklisted
    blacklisted_by: UUID  # Admin who blacklisted
    blacklisted_at: datetime
    lifted_at: datetime   # NULL = still blacklisted
```

Blacklisted devices are checked in `get_current_user()` — any request from a blacklisted device returns `401`.

---

## Security Incident Auto-Detection

The system auto-logs `SecurityIncident` when:
- A device attempts to register for a property it doesn't belong to
- A device fingerprint mismatch is detected in JWT verification
- More than 5 failed login attempts from the same device

---

## Cross-References

- Authentication with device binding: [09-auth-security.md](./09-auth-security.md)
- Device model: [04-database.md](./04-database.md)
- Subscription device limits: [12-subscriptions.md](./12-subscriptions.md)
