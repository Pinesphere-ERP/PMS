# 9. Authentication and Security

## Overview

The system uses **JWT (JSON Web Token)** based authentication with:
- Stateful session tracking (JWT revocation via `user_sessions` table)
- Device fingerprint binding (JWT is tied to the device that issued it)
- Role-based access control (RBAC) via `roles`, `permissions`, `role_permissions` tables
- Account lockout after 5 failed login attempts
- Multi-property access grants via `user_property_access` table

---

## Authentication Components

### 1. JWT Structure

**Access Token** (30-minute expiry):
```json
{
  "sub": "user-uuid",
  "tenant_id": "property-uuid",
  "jti": "unique-token-id-uuid",
  "device_fp": "device-fingerprint-string",
  "exp": 1234567890,
  "type": "access"
}
```

**Refresh Token** (7-day expiry):
```json
{
  "sub": "user-uuid",
  "jti": "unique-token-id-uuid",
  "device_fp": "device-fingerprint-string",
  "family": "refresh-family-uuid",
  "exp": 1234567890,
  "type": "refresh"
}
```

**Algorithm:** HS256  
**Secret:** `SECRET_KEY` environment variable

### 2. Session Tracking (user_sessions table)

Every successful login creates a `UserSession` record:
```
UserSession {
  id, user_id, device_id,
  session_token,     -- full JWT
  is_offline_session,
  issued_at, expires_at,
  revoked_at,        -- NULL = active
  revoked_reason
}
```

**When a user logs in:**
- Previous sessions for the same device are revoked (`revoked_at` set).
- New session created.

**On every API call:**
- `get_current_user()` decodes JWT, checks `jti` against `user_sessions`.
- If `revoked_at` is not NULL, returns `401 Unauthorized`.
- If `expires_at` is past, returns `401 Unauthorized`.

### 3. Device Fingerprint Binding

Every JWT embeds `device_fp` (device fingerprint / `device_uid`).

`get_current_user()` verifies:
1. `device_fp` in JWT matches the device's `Device.device_uid` in the database.
2. Device status is `approved` or `active`.
3. Device is not in `device_blacklist`.

If device fingerprint doesn't match: `401 Unauthorized`.

---

## get_current_user() — Complete Flow

```python
async def get_current_user(
    request: Request,
    authorization: str = Header(None),
    db: AsyncSession = Depends(get_db)
) -> User:

    1. Extract Bearer token from Authorization header
    2. decode_access_token(token) -> payload
    3. Extract user_id = payload["sub"]
    4. Extract jti = payload["jti"]
    5. Extract device_fp = payload["device_fp"]
    6. SELECT User WHERE id == user_id
    7. If user.status == "LOCKED" -> 403
    8. SELECT UserSession WHERE session_token LIKE jti AND revoked_at IS NULL
    9. If no active session -> 401
    10. If session.expires_at < now -> 401
    11. Check device blacklist (DeviceBlacklist WHERE device_uid == device_fp)
    12. Check device status (Device WHERE device_uid == device_fp AND status in ['approved', 'active'])
    13. Resolve active_property_id:
        a. Read X-Active-Property-Id header
        b. If set, validate via UserPropertyAccess
        c. If not set, use User.property_id
    14. Inject user.active_property_id = resolved_property_id
    15. Return user
```

---

## RBAC (Role-Based Access Control)

### Role Hierarchy

```
SUPER_ADMIN > OWNER > PROPERTY_MANAGER > RECEPTIONIST
                                        > HOUSEKEEPING
                                        > KITCHEN
                                        > ACCOUNTANT
                                        > SECURITY_GUARD
                                        > BROKER
```

### Access Levels (in `role_permissions`)

| Level | Code | Meaning |
|-------|------|---------|
| No Access | NONE | Cannot access this module |
| View Only | VIEW | Can read, cannot modify |
| Own Records | OWN | Can modify own records only |
| Limited Access | LIMITED | Predefined subset of operations |
| Full Access | FULL | Complete CRUD on this module |

### Permission Codes

Format: `<module>.<action>`

Examples:
- `booking.view`
- `booking.create`
- `booking.cancel`
- `checkin.process`
- `checkout.process`
- `payment.collect`
- `housekeeping.update_status`
- `report.view`
- `user.manage`

### require_permission() — Permission Check

```python
def require_permission(permission_code: str, min_level: str = "VIEW"):
    async def dependency(
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db)
    ):
        role = await get_current_role(current_user, db)
        
        # Super Admin bypasses all checks
        if role.role_code == "SUPER_ADMIN":
            return
        
        # Find permission assignment for this role
        rp = await db.execute(
            SELECT(RolePermission)
            .JOIN(Permission)
            .WHERE(RolePermission.role_id == role.id)
            .WHERE(Permission.permission_code == permission_code)
        )
        
        if not rp or ACCESS_LEVEL_ORDER[rp.access_level] < ACCESS_LEVEL_ORDER[min_level]:
            raise HTTPException(403, "Insufficient permissions")
```

### assert_property_access() — Property Isolation

```python
async def assert_property_access(
    property_id: uuid.UUID,
    current_user: User,
    db: AsyncSession
):
    # Super Admin can access any property
    role = await get_current_role(current_user, db)
    if role.role_code == "SUPER_ADMIN":
        return
    
    # Check if user has any access to this property
    if current_user.property_id == property_id:
        return  # Primary property
    
    # Check UserPropertyAccess for multi-property access
    access = await db.execute(
        SELECT(UserPropertyAccess)
        .WHERE(UserPropertyAccess.user_id == current_user.id)
        .WHERE(UserPropertyAccess.property_id == property_id)
        .WHERE(UserPropertyAccess.status == "ACTIVE")
    )
    if not access.scalars().first():
        raise HTTPException(403, "Access to this property is not permitted")
```

---

## Account Lockout

`User.failed_login_attempts` is incremented on every failed login attempt.

At **5 failed attempts**: `User.status = "LOCKED"`.

A locked user:
- Cannot log in (returns 403).
- Cannot request OTP.
- Must be unlocked by a Super Admin via `PATCH /users/{id}` setting `status = "ACTIVE"`.

---

## Device Blacklist

Any device can be added to `device_blacklist` by a Super Admin:
```
DeviceBlacklist {
  device_uid, reason, blacklisted_by, blacklisted_at, lifted_at
}
```

If `lifted_at` is NULL, device is still blacklisted.

Blacklisted devices:
- Cannot log in (returns 400).
- Cannot access any API (returns 401 via `get_current_user`).

---

## OTP System

OTPs are used for:
- Account unlock (user requests OTP to reset locked account)
- Guest portal authentication (booking_reference + OTP)
- Password reset

**OTP Generation:**
```python
otp = "".join(random.choices(string.digits, k=6))  # 6-digit numeric
otp_hash = bcrypt.hash(otp)
```

Stored in `otp_requests` table with:
- `purpose` — account_unlock, guest_portal, password_reset
- `expires_at` — 10 minutes from creation
- `used_at` — NULL until used

**OTP Verification:**
1. Find latest unused, unexpired OTP for the identifier.
2. bcrypt verify.
3. If valid, set `used_at = now()`.
4. Issue auth tokens.

---

## CORS Configuration

Configured in `main.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # All origins allowed (restrictable via CORS_ORIGINS env var)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**Production recommendation:** Set `allow_origins` to the specific admin portal domain.

---

## Rate Limiting

Uses **SlowAPI** (wrapper around `limits` library):
- Configured per endpoint with `@limiter.limit("N/minute")`
- Login endpoint is rate-limited (e.g., 10 per minute per IP)
- Protects against brute force and DoS

---

## Audit Trail Security

`audit_logs` implements a **hash chain** for tamper detection:
- `entry_hash` — SHA-256 of the log entry data
- `previous_log_hash` — SHA-256 of the previous entry

If an entry is modified or deleted, the chain breaks. A Super Admin audit tool can verify chain integrity.

---

## Multi-Property Security

When an owner or super admin accesses a property that isn't their primary property:
1. Request includes `X-Active-Property-Id` header.
2. `get_current_user()` validates via `UserPropertyAccess` table.
3. `user.active_property_id` is set to the requested property.
4. All subsequent queries in that request use `active_property_id` for filtering.

This prevents cross-property data leakage even for multi-property owners.

---

## Security Incident Logging

Critical security events are automatically logged to `security_incidents`:
- Failed login attempts (after threshold)
- Device blacklist triggers
- JWT tampering attempts
- Cross-property access attempts

---

## Password Policy

- Minimum: 8 characters
- Stored as: bcrypt hash (strength factor 12)
- PIN: 4-6 digits, stored as bcrypt hash

---

## Cross-References

- User model: [04-database.md#users](./04-database.md)
- Login flow: [05-backend.md#auth](./05-backend.md)
- Device management: [15-device-management.md](./15-device-management.md)
