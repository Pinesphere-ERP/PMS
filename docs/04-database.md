# 4. Database Documentation

## Overview

The database uses **PostgreSQL** in production (Neon Serverless) and **SQLite** for local development.

All models are defined in:
`pinesphere_backend/app/infra/models.py`

The schema uses:
- UUID primary keys throughout (no auto-increment integers)
- `TimestampMixin` for `created_at` / `updated_at` on all tables
- `SyncMixin` for offline-first tables (adds `last_modified_hlc`, `is_deleted`, `deleted_at`, `device_id`)
- `JSONB` for flexible structured data (falls back to `JSON` on SQLite)

---

## Database Mixins

### TimestampMixin
Applied to nearly every table.
```python
created_at: datetime  # server-side default, set at INSERT
updated_at: datetime  # server-side default, updated on every UPDATE
```

### SyncMixin
Applied to tables that the mobile app syncs offline.
```python
last_modified_hlc: str   # Hybrid Logical Clock timestamp for sync ordering
is_deleted: bool         # Soft delete flag
deleted_at: datetime     # When soft-deleted
device_id: str           # ID of device that last modified this record
```

---

## Entity Relationship Overview

```
owners
  |-- businesses (owner_id FK)
  |-- properties (owner_id FK)
       |-- property_addresses (property_id FK, unique)
       |-- property_images (property_id FK)
       |-- property_documents (property_id FK)
       |-- bank_accounts (property_id FK)
       |-- property_verifications (property_id FK, unique)
       |-- property_amenities (property_id FK)
       |-- room_categories (property_id FK)
       |    |-- rooms (room_category_id FK, property_id FK)
       |-- users (property_id FK)
       |    |-- user_property_access (user_id FK, property_id FK)
       |    |-- user_sessions (user_id FK)
       |    |-- user_devices (user_id FK)
       |-- devices (property_id FK)
       |-- subscriptions (property_id FK)
       |-- guests (property_id FK)
       |    |-- bookings (guest_id FK, room_id FK, property_id FK)
       |         |-- check_ins (booking_id FK)
       |         |-- check_outs (booking_id FK)
       |         |-- invoices (booking_id FK)
       |         |    |-- invoice_items
       |         |-- payments (booking_id FK)
       |         |-- folio_line_items (booking_id FK)
       |-- housekeeping_tasks (room_id FK, property_id FK)
       |-- maintenance_tickets (room_id FK, property_id FK)
       |-- audit_logs (property_id FK)
       |-- tasks (property_id FK)
       |-- notifications (recipient_id FK -> users)
       |-- pricing_rules (property_id FK)
       |-- security_incidents (property_id FK)
       |-- security_cameras (property_id FK)
       |-- watchlist (property_id FK)
       |-- visitor_logs (property_id FK)
       |-- vehicle_logs (property_id FK)
       |-- broker_commission_rules (property_id FK)
       |-- broker_wallets (property_id FK)
       |-- form_c_records (property_id FK)
       |-- service_requests (property_id FK)
       |-- housekeeping_room_status (property_id FK)
```

---

## Table Reference

### owners
**Purpose:** Stores hotel/property owners who are the primary clients of the platform.
| Column | Type | Notes |
|--------|------|-------|
| owner_id | UUID PK | |
| full_name | String(150) | Required |
| mobile_number | String(15) | Unique, Required |
| email | String(150) | Unique, Required |
| designation | String(50) | Optional |
| alternate_contact | String(15) | Optional |
| mobile_verified | Boolean | Default false |
| email_verified | Boolean | Default false |
| pan_number | String(10) | Optional, KYC |
| aadhaar_number | String(20) | Optional, KYC |
| selfie_url | Text | Optional |
| password_hash | Text | Optional (owners may log in directly) |
**Created by:** Super Admin during property onboarding  
**Relations:** 1:N to `businesses`, 1:N to `properties`

---

### businesses
**Purpose:** Legal business entity (company or individual) that owns properties. Used for GST and compliance tracking.
| Column | Type | Notes |
|--------|------|-------|
| business_id | UUID PK | |
| owner_id | UUID FK(owners) | Required |
| business_name | String(200) | Required |
| business_type | String(30) | e.g., "Proprietorship", "Pvt Ltd" |
| business_reg_number | String(50) | Optional |
| gst_number | String(15) | Optional |
| gst_certificate_url | Text | Optional |
| pan_number | String(10) | Optional |

---

### properties
**Purpose:** The core entity. Each hotel/resort/homestay is a property.
| Column | Type | Notes |
|--------|------|-------|
| property_id | UUID PK | |
| business_id | UUID FK(businesses) | Required |
| owner_id | UUID FK(owners) | Required (denormalized for easy access) |
| property_name | String(200) | Required |
| property_type | String(30) | hotel, resort, homestay, etc. |
| star_category | SmallInt | 1-5 stars |
| year_established | SmallInt | |
| total_floors | SmallInt | |
| total_rooms | Integer | |
| description | Text | |
| city | String(100) | |
| cover_image | String(500) | |
| onboarding_status | String(20) | draft, in_progress, complete, approved |
| primary_device_id | UUID | First device registered |
| whatsapp_number | String(15) | For outbound WhatsApp notifications |
| created_by_admin_id | UUID | Super Admin who created it |
**SyncMixin:** Yes (synced to mobile)

---

### property_addresses
**Purpose:** Full address and geo-location for a property.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | UUID FK(properties) | Unique (1:1 with property) |
| address | Text | Full street address |
| landmark | String(200) | |
| city | String(100) | |
| state | String(100) | |
| country | String(100) | |
| pincode | String(20) | |
| latitude | Numeric(10,6) | |
| longitude | Numeric(10,6) | |
| google_maps_url | Text | |

---

### property_images
**Purpose:** Gallery images for a property.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | UUID FK(properties) | CASCADE delete |
| image_type | String(50) | e.g., "lobby", "room", "exterior" |
| image_url | Text | URL in MinIO or local /uploads |
| display_order | Integer | Sort order for display |
| is_primary | Boolean | Cover image flag |

---

### property_documents
**Purpose:** Legal and compliance documents (trade license, fire NOC, FSSAI, etc.)
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | UUID FK(properties) | CASCADE delete |
| document_type | String(50) | e.g., "trade_license" |
| document_number | String(100) | License/reg number |
| document_url | Text | Uploaded document file |
| verification_status | String(30) | pending, verified, rejected |
| verified_by | UUID FK(users) | Admin who verified |
| verified_at | DateTime | |
| remarks | Text | |

---

### bank_accounts
**Purpose:** Bank account details for a property for subscription billing and owner payouts.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | UUID FK(properties) | CASCADE delete |
| bank_name | String(150) | Required |
| account_holder_name | String(150) | Required |
| account_number | String(100) | Required |
| ifsc_code | String(20) | Required |
| upi_id | String(100) | Optional |
| cancelled_cheque_url | Text | Optional |

---

### property_verifications
**Purpose:** Tracks which verification steps have been completed for a property (KYC checklist).
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | UUID FK(properties) | Unique (1:1) |
| mobile_verified | Boolean | |
| email_verified | Boolean | |
| pan_verified | Boolean | |
| gst_verified | Boolean | |
| bank_verified | Boolean | |
| ownership_verified | Boolean | |
| documents_verified | Boolean | |
| photos_verified | Boolean | |
| map_verified | Boolean | |
| verification_score | Integer | 0-100 |
| status | String(30) | pending, verified, rejected |
| review_required | Boolean | |
| verified_by | UUID FK(users) | |
| verified_at | DateTime | |
| remarks | Text | |

---

### amenities
**Purpose:** Master catalog of amenities (WiFi, Pool, etc.)
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| name | String(100) | Unique |
| category | String(50) | e.g., "room", "property" |
| icon_name | String(50) | Icon identifier |

---

### property_amenities
**Purpose:** Which amenities a property has (many-to-many join).
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | UUID FK(properties) | CASCADE |
| amenity_id | UUID FK(amenities) | CASCADE |
**Constraint:** UNIQUE(property_id, amenity_id)

---

### roles
**Purpose:** Role definitions (system-level and custom per property).
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | UUID FK(properties) | NULL for system roles |
| role_code | String(40) | SUPER_ADMIN, OWNER, RECEPTIONIST, etc. |
| role_name | String(80) | Display name |
| is_system_role | Boolean | True for built-in roles |
| description | Text | |
**Constraint:** UNIQUE(property_id, role_code)

---

### permissions
**Purpose:** Fine-grained permission codes per module.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| permission_code | String(60) | Unique, e.g., "booking.view" |
| module_name | String(60) | e.g., "bookings" |
| description | Text | |

---

### role_permissions
**Purpose:** Assigns permissions to roles with an access level.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| role_id | UUID FK(roles) | CASCADE |
| permission_id | UUID FK(permissions) | CASCADE |
| access_level | String(20) | NONE, VIEW, OWN, LIMITED, FULL |
**Constraint:** UNIQUE(role_id, permission_id)

---

### users
**Purpose:** All system users (staff, owners, Super Admin). Not guests.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | UUID FK(properties) | NULL for SUPER_ADMIN |
| role_id | UUID FK(roles) | Required |
| name | String(120) | Required |
| mobile_number | String(15) | Unique |
| email | String(120) | Optional |
| username | String(60) | Unique, Optional |
| password_hash | String(255) | bcrypt hash |
| pin_hash | String(255) | 4-6 digit PIN for quick mobile login |
| biometric_enabled | Boolean | |
| is_primary_owner | Boolean | |
| status | String(20) | ACTIVE, INACTIVE, LOCKED |
| failed_login_attempts | SmallInt | Increment on failed login |
| profile_photo_url | Text | |
| created_by | UUID FK(users) | Who created this user |
| is_pending_sync | Boolean | For sync pipeline |
**SyncMixin:** Yes  
**Constraints:** UNIQUE(mobile_number), UNIQUE(username)

---

### user_property_access
**Purpose:** Grants a user access to multiple properties with different roles (multi-property owners or staff).
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| user_id | UUID FK(users) | CASCADE |
| property_id | UUID FK(properties) | CASCADE |
| role_id | UUID FK(roles) | Role in this specific property |
| status | String(20) | ACTIVE, INACTIVE |
**Constraint:** UNIQUE(user_id, property_id)

---

### devices
**Purpose:** Physical devices (tablets/phones) registered for a property.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| device_uid | String(128) | Unique device fingerprint |
| property_id | UUID FK(properties) | CASCADE |
| primary_user_id | UUID FK(users) | Optional |
| device_name | String(80) | |
| os_type | String(20) | android, ios, windows |
| status | String(20) | pending_approval, approved, active, revoked |

---

### user_sessions
**Purpose:** Tracks active login sessions for JWT revocation.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| user_id | UUID FK(users) | CASCADE |
| device_id | UUID FK(devices) | Optional |
| session_token | String(500) | Full JWT (unique) |
| is_offline_session | Boolean | |
| issued_at | DateTime | |
| expires_at | DateTime | |
| revoked_at | DateTime | NULL = active session |
| revoked_reason | String(120) | |

---

### room_categories
**Purpose:** Room types within a property (e.g., "Deluxe", "Suite").
| Column | Type | Notes |
|--------|------|-------|
| room_category_id | UUID PK | |
| property_id | UUID FK(properties) | Required |
| room_name | String(100) | e.g., "Deluxe Room" |
| number_of_rooms | Integer | Count of rooms in this category |
| base_price | Numeric(10,2) | Base nightly rate |

---

### rooms
**Purpose:** Individual physical rooms within a property.
| Column | Type | Notes |
|--------|------|-------|
| room_id | UUID PK | |
| property_id | UUID FK(properties) | Required |
| room_category_id | UUID FK(room_categories) | Required |
| room_number | String(20) | e.g., "101", "302A" |
| floor | String(10) | e.g., "1", "Ground" |
| housekeeping_status | String(20) | clean, dirty, cleaning, maintenance |
| occupancy_status | String(20) | vacant, occupied, reserved |
| image_url | Text | |
**SyncMixin:** Yes

---

### guests
**Purpose:** Guest records created during booking. Not a login account (separate from users).
| Column | Type | Notes |
|--------|------|-------|
| guest_id | UUID PK | |
| property_id | UUID FK(properties) | Required |
| full_name | String(150) | Required |
| mobile | String(15) | |
| email | String(150) | |
**SyncMixin:** Yes

---

### bookings
**Purpose:** Core booking record. Links guest, room, dates, and financial summary.
| Column | Type | Notes |
|--------|------|-------|
| booking_id | UUID PK | |
| property_id | UUID FK(properties) | |
| room_id | UUID FK(rooms) | |
| guest_id | UUID FK(guests) | |
| booking_type | String(20) | walkin, advance, online |
| booking_source | String(30) | direct, broker, OTA |
| broker_user_id | UUID FK(users) | NULL unless source=broker |
| booking_reference | String(30) | Unique human-readable ref (e.g., "PSY-2024-001") |
| check_in_date | Date | Required |
| check_out_date | Date | Required |
| adults | Integer | |
| children | Integer | |
| room_rent | Numeric(10,2) | |
| deposit | Numeric(10,2) | |
| discount | Numeric(10,2) | |
| taxes | Numeric(10,2) | |
| total_payable | Numeric(10,2) | |
| advance_paid | Numeric(10,2) | |
| pending_amount | Numeric(10,2) | |
| booking_status | String(20) | confirmed, cancelled, checked_in, checked_out |
| payment_status | String(20) | pending, partial, paid |
| sync_status | String(20) | synced, pending |
| notes | Text | |
**SyncMixin:** Yes  
**Constraint:** UNIQUE(booking_reference)

---

### check_ins
**Purpose:** Records the actual check-in event. Created when receptionist processes check-in.
| Column | Type | Notes |
|--------|------|-------|
| checkin_id | UUID PK | |
| property_id, booking_id, room_id, guest_id | FKs | |
| staff_id | UUID FK(users) | Who processed check-in |
| deposit | Numeric(10,2) | Deposit collected at check-in |
| advance_paid | Numeric(10,2) | |
| id_verified | Boolean | ID document verified? |
| checked_in_at | DateTime | Actual check-in timestamp |
| status | String(20) | active, completed |
| special_requests | Text | Guest requests at check-in |
**SyncMixin:** Yes

---

### check_outs
**Purpose:** Records the check-out event with final billing.
| Column | Type | Notes |
|--------|------|-------|
| checkout_id | UUID PK | |
| property_id, checkin_id, booking_id, room_id | FKs | |
| staff_id | UUID FK(users) | Who processed check-out |
| checkout_time | DateTime | |
| total_amount | Numeric(10,2) | Final total |
| advance_paid | Numeric(10,2) | |
| remaining_balance | Numeric(10,2) | |
| payment_status | String(20) | paid, partial, pending |
| checkout_status | String(20) | pending, completed |
**SyncMixin:** Yes

---

### invoices
**Purpose:** Billing document generated at check-out.
| Column | Type | Notes |
|--------|------|-------|
| invoice_id | UUID PK | |
| property_id, booking_id, guest_id | FKs | |
| invoice_number | String(50) | Unique, auto-generated |
| date | Date | Invoice date |
| due_date | Date | |
| amount | Numeric(10,2) | Total invoice amount |
| gst | Numeric(10,2) | |
| status | String(20) | Pending, Paid, Cancelled |

---

### invoice_items
**Purpose:** Line items on an invoice (room charges, F&B, taxes, etc.)
| Column | Type | Notes |
|--------|------|-------|
| item_id | UUID PK | |
| invoice_id | UUID FK(invoices) | |
| description | String(200) | |
| category | String(30) | room, food, service, tax |
| quantity | Integer | |
| unit_price | Numeric(10,2) | |
| total_price | Numeric(10,2) | |
| remarks | Text | |

---

### folio_line_items
**Purpose:** Real-time guest billing folio. Charges added during stay (room, F&B, extras).
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| booking_id | UUID FK(bookings) | CASCADE |
| property_id | FK | |
| category | String(30) | room, food, minibar, laundry, etc. |
| description | String(200) | |
| quantity | Integer | |
| unit_price | Numeric(10,2) | |
| amount | Numeric(10,2) | |
| added_by | UUID FK(users) | |
| is_void | Boolean | Can be voided (not deleted) |
| voided_by | UUID FK(users) | |
| voided_at | DateTime | |

---

### payments
**Purpose:** Individual payment transactions made by guests.
| Column | Type | Notes |
|--------|------|-------|
| payment_id | UUID PK | |
| invoice_id | UUID FK(invoices) | Optional |
| booking_id | UUID FK(bookings) | Optional |
| transaction_id | String(100) | Unique (Razorpay ID or manual ref) |
| reference_number | String(100) | |
| payment_mode | String(20) | cash, upi, card, bank_transfer |
| amount | Numeric(10,2) | |
| upi_id | String(100) | |
| bank_name | String(100) | |
| card_last4 | String(4) | |
| collected_by | UUID FK(users) | |
| remarks | Text | |
| status | String(20) | pending, completed, failed |
| synced | Boolean | |
**SyncMixin:** Yes

---

### audit_logs
**Purpose:** Immutable audit trail. Every significant user action is logged here.
| Column | Type | Notes |
|--------|------|-------|
| log_id | UUID PK | |
| property_id | UUID FK(properties) | Optional |
| user_id | UUID FK(users) | Who performed the action |
| device_id | String(100) | Device identifier |
| timestamp | DateTime | |
| module_name | String(50) | e.g., "bookings", "checkin" |
| action_type | String(50) | e.g., "CREATE", "UPDATE", "DELETE" |
| target_entity | String(50) | Table name |
| target_record_id | UUID | PK of affected record |
| old_value_snapshot | JSONB | State before change |
| new_value_snapshot | JSONB | State after change |
| ip_address | String(45) | Client IP |
| previous_log_hash | String(64) | Chain hash for tamper detection |
| entry_hash | String(64) | SHA-256 of this entry |
**Indexes:** timestamp, (target_entity, target_record_id)

---

### notifications
**Purpose:** In-app notifications delivered to users.
| Column | Type | Notes |
|--------|------|-------|
| notification_id | UUID PK | |
| recipient_id | UUID FK(users) | CASCADE |
| title | String(150) | |
| message | Text | |
| channel | String(20) | in_app, whatsapp, push |
| priority | String(20) | normal, high, critical |
| status | String(20) | unread, read, dismissed, failed |
| read_at | DateTime | |
| payload | JSONB | Extra data (task_id, booking_id, etc.) |
**SyncMixin:** Yes

---

### housekeeping_tasks
**Purpose:** Cleaning tasks assigned to housekeeping staff.
| Column | Type | Notes |
|--------|------|-------|
| task_id | UUID PK | |
| property_id, room_id | FKs | |
| assigned_staff_id | UUID FK(users) | |
| status | String(20) | pending, in_progress, completed |
| priority | String(10) | low, medium, high |
| checklist_status | JSONB | Checklist items and completion status |
| remarks | Text | |
| completed_at | DateTime | |
**SyncMixin:** Yes

---

### maintenance_tickets
**Purpose:** Maintenance issues reported for rooms.
| Column | Type | Notes |
|--------|------|-------|
| ticket_id | UUID PK | |
| property_id, room_id | FKs | |
| reported_by, assigned_to | UUID FK(users) | |
| category | String(30) | plumbing, electrical, carpentry, etc. |
| priority | String(10) | |
| issue_description | Text | |
| status | String(20) | open, in_progress, resolved |
| resolved_at | DateTime | |
**SyncMixin:** Yes

---

### subscriptions
**Purpose:** Platform subscription for a property. Gates access to operational features.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | UUID FK(properties) | |
| plan | String(50) | "Free Trial", "Basic", "Pro", etc. |
| billing_cycle | String(20) | Monthly, Annual |
| start_date | Date | |
| expiry_date | Date | |
| status | String(20) | Active, Expired, Suspended |
| license_id | String(100) | Unique license code |
| device_limit | Integer | Max devices allowed |
| registered_devices | Integer | Currently registered |
| subscription_required | Boolean | |

---

### otp_requests
**Purpose:** Stores hashed OTPs for account unlock, guest portal authentication, etc.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| user_id | UUID FK(users) | Optional (guest OTPs have no user_id) |
| booking_id | UUID FK(bookings) | For guest portal OTP |
| otp_hash | String(255) | bcrypt hash of the OTP |
| purpose | String(40) | account_unlock, guest_portal, password_reset |
| expires_at | DateTime | |
| used_at | DateTime | NULL = not yet used |

---

### pricing_rules
**Purpose:** Dynamic pricing rules applied during booking creation.
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | FK | |
| name | String(150) | |
| rule_type | String(30) | weekend, seasonal, occupancy, last_minute |
| condition_json | JSONB | Rule conditions |
| multiplier | Numeric(6,4) | Price multiplier |
| flat_adjustment | Numeric(10,2) | Fixed amount adjustment |
| priority | Integer | Higher priority rules take precedence |
| effective_from, effective_until | Date | |
| days_of_week | String(20) | e.g., "6,7" for Sat/Sun |
| is_active | Boolean | |

---

### tasks
**Purpose:** Unified task management across housekeeping, kitchen, maintenance, and service requests.
| Column | Type | Notes |
|--------|------|-------|
| task_id | UUID PK | |
| property_id, room_id, booking_id | FKs | |
| task_type | String(50) | cleaning, maintenance, food, service |
| status | String(20) | pending, accepted, in_progress, completed, closed |
| priority | String(20) | normal, high, emergency |
| assigned_to, requested_by_user_id, requested_by_guest_id | FKs | |
| description | Text | |
| due_at, completed_at | DateTime | |
| photos | Text | JSON list of photo URLs |
| remarks | Text | |
**SyncMixin:** Yes

---

### security_incidents
**Purpose:** Platform-level security events (failed logins, tampered devices, etc.)
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| property_id | FK | Optional |
| incident_type | String(50) | |
| severity | String(20) | low, medium, high, critical |
| user_id, device_uid, ip_address | | |
| description | Text | |
| status | String(20) | open, investigating, resolved |

---

### form_c_records
**Purpose:** Legal Form C declarations required for foreign national guests within 24 hours of check-in (Indian law compliance).
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| guest_id, booking_id, property_id | FKs | |
| nationality_doc_id | FK(guest_nationality_documents) | |
| status | String(20) | generated, submitted |
| generated_at | DateTime | |
| deadline_at | DateTime | 24 hours after check-in |
| submitted_at | DateTime | |
| pdf_url | Text | Generated PDF |

---

### service_requests
**Purpose:** Service requests submitted by guests or staff (room service, housekeeping, maintenance, etc.)
Has a CHECK constraint ensuring either `requested_by_guest_id` OR `requested_by_user_id` is set, not both.
| Column | Type | Notes |
|--------|------|-------|
| request_id | UUID PK | |
| property_id, booking_id, room_id | FKs | |
| requested_by_guest_id OR requested_by_user_id | FKs | Mutually exclusive |
| request_category | String(30) | housekeeping, maintenance, food, other |
| title | String(150) | |
| description | Text | |
| priority, status | String | |
| assigned_to, completed_by, verified_by | FK(users) | |
| manager_verified | Boolean | |
**SyncMixin:** Yes

---

## Key Relationships Summary

| Relationship | Cardinality | Notes |
|-------------|-------------|-------|
| Owner -> Properties | 1:N | One owner can have many properties |
| Property -> Users | 1:N | Staff assigned to one property |
| User -> UserPropertyAccess | 1:N | Allows multi-property access |
| Property -> RoomCategories | 1:N | Each property defines its room types |
| RoomCategory -> Rooms | 1:N | Each type has multiple physical rooms |
| Property -> Guests | 1:N | Guest records per property |
| Booking -> Guest + Room | N:1 each | One booking per guest per room per date |
| CheckIn -> Booking | 1:1 | One check-in per booking |
| CheckOut -> CheckIn | 1:1 | One check-out per check-in |
| Booking -> Payments | 1:N | Multiple payment installments |
| Booking -> FolioLineItems | 1:N | Charges accumulate during stay |
| Booking -> Invoice | 1:1 | Generated at check-out |

---

## Cross-References

- Authentication and sessions: [09-auth-security.md](./09-auth-security.md)
- Booking flow: [14-booking-flow.md](./14-booking-flow.md)
- Sync engine: [10-sync-engine.md](./10-sync-engine.md)
