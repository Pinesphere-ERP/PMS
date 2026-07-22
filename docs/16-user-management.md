# 16. User Management

## Overview

Users are staff members, owners, and the super admin who access the system. Not to be confused with Guests (who are non-login customers).

---

## User Model

```python
class User:
    id: UUID
    property_id: UUID       # NULL for SUPER_ADMIN
    role_id: UUID           # FK to roles
    name: str               # Display name
    mobile_number: str      # Unique, used for login
    email: str              # Optional, used for login
    username: str           # Optional, unique
    password_hash: str      # bcrypt hash
    pin_hash: str           # For quick PIN login on mobile
    biometric_enabled: bool
    is_primary_owner: bool  # True for the owner of the property
    status: str             # ACTIVE, INACTIVE, LOCKED
    failed_login_attempts: int
    profile_photo_url: str
    created_by: UUID        # Who created this user
```

---

## User Creation Flow (Super Admin Portal)

**Route:** `POST /users`

**Validation:**
- `property_id` must be a valid UUID (not a plain string like "test")
- `role_id` must be a valid UUID pointing to an existing role
- `mobile_number` must be unique across all users
- `username` must be unique (if provided)
- `password` minimum 8 characters

**What gets created:**
1. `User` record with bcrypt-hashed password
2. If `property_id` is provided, user is associated with that property
3. `UserPropertyAccess` record if multi-property access is granted

**API:**
```json
POST /users
{
  "name": "Jane Receptionist",
  "mobile_number": "+911234567890",
  "email": "jane@hotel.com",
  "username": "jane_hotel",
  "password": "secure123",
  "role_id": "uuid-of-receptionist-role",
  "property_id": "uuid-of-property"
}
```

**Common Error:** `Input should be a valid UUID, invalid character: found 't' at 1`  
**Cause:** `property_id` or `role_id` field is receiving a plain string ("test") instead of a valid UUID.  
**Fix:** Ensure the form passes actual UUID values from the database, not placeholder strings.

---

## Role Assignment

Each user has exactly one primary role (`role_id` FK).

For multi-property access, additional role assignments per property are stored in `user_property_access`:
```python
class UserPropertyAccess:
    user_id: UUID
    property_id: UUID
    role_id: UUID     # Role in THIS specific property
    status: str       # ACTIVE, INACTIVE
```

---

## Staff Management

**Module:** `app/modules/staff/`

Key operations:
- List all staff for a property
- Create staff with invitation link (future — currently direct creation)
- Reset staff credentials
- Deactivate staff
- Change staff role

---

## User Directory (Admin Portal)

**Route:** `/users`  
**File:** `src/pages/UserManagement/UserManagement.jsx`

**Features:**
- List all users with filter by property, role, status
- Search by name, email, username, mobile
- View user details
- Create user button

---

## Create User For Property

**Route:** `/properties/:id/users/create`  
**File:** `src/pages/UserManagement/CreateUserForProperty.jsx`

**Pre-fills:** Property from URL param.

**Steps:**
1. Load property details (property name display).
2. Load roles available for this property.
3. Fill form: name, mobile, email, username, password, role.
4. Submit: `POST /users` with `property_id` = property from URL.

---

## Roles Reference

| Role Code | Allowed to do |
|-----------|--------------|
| SUPER_ADMIN | Everything on the platform |
| OWNER | View all their properties, reports, staff |
| PROPERTY_MANAGER | Full operational access to their property |
| RECEPTIONIST | Bookings, check-in, check-out, guests |
| HOUSEKEEPING | View and update room/task status |
| KITCHEN | View F&B orders, update order status |
| ACCOUNTANT | View payments, invoices, financial reports |
| SECURITY_GUARD | Log visitors, vehicles, incidents |
| BROKER | View commission wallet, bookings they referred |

---

## Account Lockout and Unlock

After 5 failed logins, `User.status = "LOCKED"`.

To unlock:
```
PATCH /users/{user_id}
{ "status": "ACTIVE", "failed_login_attempts": 0 }
```

Only Super Admin or Property Manager can unlock accounts.

---

## Cross-References

- Authentication: [09-auth-security.md](./09-auth-security.md)
- RBAC: [09-auth-security.md](./09-auth-security.md)
- User model: [04-database.md](./04-database.md)
