# 6. API Reference

## Base URL

| Environment | URL |
|-------------|-----|
| Production | `https://pms-bvko.onrender.com/api/v1` |
| Development | `http://localhost:8000/api/v1` |

## Standard Response Format

All endpoints return:
```json
{
  "success": true,
  "message": "Success",
  "data": <payload>,
  "pagination": null,
  "meta": null
}
```

Error format:
```json
{
  "success": false,
  "message": "Human-readable error",
  "data": { "detail": "..." }
}
```

## Authentication Headers

| Header | Value | Required |
|--------|-------|----------|
| `Authorization` | `Bearer <access_token>` | Yes (most endpoints) |
| `X-Tenant-ID` | `<property_uuid>` | Optional (for multi-tenant routing) |
| `X-Active-Property-Id` | `<property_uuid>` | Optional (for multi-property access) |
| `X-Client-Platform` | `web` | Optional |

---

## Authentication Endpoints

### POST /auth/login
Login with credentials.

**Request:**
```json
{
  "email": "admin@example.com",
  "password": "secret",
  "device_fingerprint": "abc123",
  "device_name": "Reception Tablet"
}
```
Alternatively use `mobile_number` or `login_id`.

**Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "role_code": "SUPER_ADMIN",
  "properties": [
    { "property_id": "uuid", "role_id": "uuid", "is_primary": true }
  ]
}
```

**Errors:**
- `401` — Invalid credentials
- `403` — Account locked
- `400` — Device blacklisted

---

### GET /auth/offline-bootstrap
Returns full user profile + permissions + properties for offline storage.

**Auth:** Bearer token required.

**Response:**
```json
{
  "user_id": "uuid",
  "name": "John Doe",
  "role_code": "RECEPTIONIST",
  "permissions": [
    { "permission_code": "booking.view", "access_level": "FULL" }
  ],
  "accessible_properties": [...]
}
```

---

### POST /auth/refresh
Refresh access token.

**Request:**
```json
{ "refresh_token": "eyJ..." }
```

**Response:**
```json
{ "access_token": "eyJ...", "refresh_token": "eyJ..." }
```

---

### POST /auth/logout
Logout current session.

**Auth:** Bearer token required.

**Response:** `{ "message": "Logged out" }`

---

### POST /auth/request-otp
Request a 6-digit OTP for login or account unlock.

**Request:**
```json
{ "identifier": "user@email.com" }
```

---

### POST /auth/verify-otp
Verify OTP and get tokens.

**Request:**
```json
{ "identifier": "user@email.com", "otp": "123456" }
```

---

## Property Endpoints

### GET /properties
List all properties.

**Auth:** Super Admin returns all; Owner returns theirs; Staff returns their property only.

**Query params:** `page`, `limit`, `search`, `status`

**Response data:**
```json
[
  {
    "property_id": "uuid",
    "property_name": "Grand Hotel",
    "property_type": "hotel",
    "city": "Mumbai",
    "onboarding_status": "complete",
    "total_rooms": 50,
    "star_category": 4
  }
]
```

---

### POST /properties
Create a new property. **Super Admin only.**

**Request:**
```json
{
  "property_name": "Grand Hotel",
  "property_type": "hotel",
  "star_category": 4,
  "total_rooms": 50,
  "owner_name": "John Doe",
  "owner_email": "john@hotel.com",
  "owner_mobile": "+911234567890",
  "business_name": "Grand Hotels Pvt Ltd"
}
```

---

### GET /properties/{property_id}
Full property detail.

**Response includes:** basic info + address + verification status + images + room categories count

---

### PATCH /properties/{property_id}
Update property fields.

---

### GET /properties/{property_id}/rooms
List all rooms for a property.

**Response data:**
```json
[
  {
    "room_id": "uuid",
    "room_number": "101",
    "floor": "1",
    "occupancy_status": "vacant",
    "housekeeping_status": "clean",
    "room_category": { "room_name": "Deluxe Room" }
  }
]
```

---

### POST /properties/{property_id}/rooms
Create a room.

**Request:**
```json
{
  "room_number": "101",
  "floor": "1",
  "room_category_id": "uuid"
}
```

---

## Booking Endpoints

### POST /bookings/guests
Create a guest record.

**Request:**
```json
{
  "property_id": "uuid",
  "full_name": "Alice Smith",
  "mobile": "+911234567890",
  "email": "alice@example.com"
}
```

---

### POST /bookings
Create a booking.

**Request:**
```json
{
  "property_id": "uuid",
  "room_id": "uuid",
  "guest_id": "uuid",
  "check_in_date": "2026-07-25",
  "check_out_date": "2026-07-28",
  "adults": 2,
  "children": 0,
  "room_rent": 5000,
  "deposit": 2000,
  "booking_type": "walkin",
  "notes": "Anniversary trip"
}
```

**Business Logic:**
- Checks room availability for the date range.
- Returns `409 Conflict` if room already booked.
- Generates a unique `booking_reference` (e.g., "PSY-2024-001").

---

### GET /bookings
List bookings.

**Query params:** `property_id`, `status` (confirmed/cancelled/checked_in/checked_out), `date`

---

### GET /bookings/{booking_id}
Full booking detail including guest name, room number, payments.

---

### PATCH /bookings/{booking_id}
Update booking details (dates, amounts, notes).

---

### POST /bookings/{booking_id}/cancel
Cancel a booking.

---

## Check-In Endpoints

### POST /checkin/{booking_id}
Process check-in.

**Request:**
```json
{
  "deposit": 2000,
  "advance_paid": 2000,
  "id_verified": true,
  "special_requests": "Non-smoking room"
}
```

**Side effects:**
- `Booking.booking_status` -> `checked_in`
- `Room.occupancy_status` -> `occupied`
- WhatsApp welcome message sent
- Audit log created

---

## Check-Out Endpoints

### POST /checkout/{booking_id}
Process check-out.

**Request:**
```json
{
  "total_amount": 15000,
  "advance_paid": 2000,
  "remaining_balance": 13000,
  "payment_status": "paid"
}
```

**Side effects:**
- `Booking.booking_status` -> `checked_out`
- `Room.occupancy_status` -> `vacant`
- `Room.housekeeping_status` -> `dirty`
- Invoice generated
- WhatsApp bill summary sent

---

## User Endpoints

### GET /users
List all users. Super Admin returns all. Others return their property's users.

**Query params:** `property_id`, `role_id`, `status`, `search`

---

### POST /users
Create a new user.

**Request:**
```json
{
  "name": "Jane Doe",
  "mobile_number": "+911234567890",
  "email": "jane@hotel.com",
  "username": "jane_receptionist",
  "password": "secure123",
  "role_id": "uuid",
  "property_id": "uuid"
}
```

**Validation:**
- `property_id` must be a valid UUID (not an empty string "test" etc.)
- Mobile and username must be unique

---

## Device Endpoints

### POST /devices/register
Register a new device for a property.

**Request:**
```json
{
  "device_uid": "abc123-fingerprint",
  "property_id": "uuid",
  "device_name": "Lobby Tablet",
  "os_type": "android"
}
```

**Response:** `{ "device_id": "uuid", "status": "pending_approval" }`

---

### GET /devices/global
All devices across all properties. **Super Admin only.**

**Query params:** `status`, `property_id`, `page`, `limit`

---

### PATCH /devices/{device_id}/approve
Approve a device.

---

### PATCH /devices/{device_id}/revoke
Revoke a device.

---

## Subscription Endpoints

### GET /subscriptions
List all subscriptions (Super Admin).

### POST /subscriptions
Create subscription for a property.

**Request:**
```json
{
  "property_id": "uuid",
  "plan": "Pro",
  "billing_cycle": "Monthly",
  "start_date": "2026-07-01",
  "expiry_date": "2026-08-01"
}
```

---

## Payment Endpoints

### POST /payments
Record a payment.

**Request:**
```json
{
  "booking_id": "uuid",
  "transaction_id": "TXN-001",
  "payment_mode": "cash",
  "amount": 5000,
  "collected_by": "uuid",
  "remarks": "Front desk payment"
}
```

---

## Sync Endpoints

### POST /sync/push
Mobile pushes offline-created records.

**Request:**
```json
{
  "property_id": "uuid",
  "records": [
    {
      "entity_type": "Booking",
      "entity_id": "uuid",
      "operation": "create",
      "payload": { ... },
      "updated_at": "2026-07-22T10:00:00Z"
    }
  ]
}
```

**Response:**
```json
{
  "accepted_ids": ["uuid"],
  "conflicts": [],
  "failed_ids": []
}
```

---

### POST /sync/pull
Mobile pulls server changes since timestamp.

**Request:**
```json
{
  "property_id": "uuid",
  "since_timestamp": "2026-07-22T00:00:00Z",
  "entity_types": ["Booking", "Room", "Guest"]
}
```

---

## Notification Endpoints

### GET /notifications
List notifications for current user.

**Query params:** `status` (unread/read/all), `page`, `limit`

---

### PATCH /notifications/{id}/read
Mark notification as read.

---

## Audit Endpoints

### GET /audit
List audit log entries.

**Query params:** `property_id`, `module_name`, `action_type`, `from_date`, `to_date`, `user_id`, `page`, `limit`

---

## Health Check

### GET /health
No auth required.

**Response:** `{ "status": "ok", "version": "1.0.0" }`

---

## Error Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request / Validation Error |
| 401 | Unauthorized (no token or revoked token) |
| 402 | Payment Required (subscription expired) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Resource Not Found |
| 409 | Conflict (e.g., room already booked) |
| 422 | Unprocessable Entity (Pydantic validation error) |
| 429 | Too Many Requests (rate limit) |
| 500 | Internal Server Error |

---

## Cross-References

- Backend implementation: [05-backend.md](./05-backend.md)
- Authentication flow: [09-auth-security.md](./09-auth-security.md)
- Booking flow: [14-booking-flow.md](./14-booking-flow.md)
