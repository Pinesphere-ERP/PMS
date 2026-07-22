# 13. Property Onboarding

## Overview

New properties go through a **multi-step onboarding wizard** before they become operational. This ensures all legal, business, and technical requirements are satisfied.

---

## Onboarding Status Values

| Status | Meaning |
|--------|---------|
| `draft` | Property created, wizard not started |
| `in_progress` | Wizard partially completed |
| `complete` | All steps completed by owner |
| `approved` | Super Admin verified and approved |

---

## Wizard Steps (Admin Portal — AddPropertyWizard.jsx)

### Step 1: Basic Information
- Property name (required)
- Property type (hotel, resort, homestay, guesthouse, motel)
- Star category (1-5)
- Year established
- Total floors
- Total rooms
- Description

### Step 2: Contact Details
- WhatsApp number (for guest notifications)

### Step 3: Location
- Street address (required)
- Landmark
- City (required)
- State (required)
- Country (required)
- Pincode (required)
- Latitude, Longitude (optional)
- Google Maps URL (optional)

### Step 4: Media (Property Images)
- Upload cover image
- Upload gallery photos (lobby, rooms, exterior)
- Tag image types

### Step 5: Ownership Details
- Owner full name (required)
- Owner mobile (required, unique)
- Owner email (required, unique)
- Owner designation
- PAN number (KYC)
- Business name

### Step 6: Room Configuration
- Create room categories:
  - Category name (e.g., "Deluxe Room")
  - Number of rooms in category
  - Base price per night
  - Bed type
  - Amenities (from amenity catalog)
- For each category, individual rooms are created later via room management

### Step 7: Review & Submit
- Preview all entered data
- Submit via `POST /properties`

---

## What Happens on Submit

`POST /properties` creates all of the following in a single transaction:
1. `Owner` record
2. `Business` record
3. `Property` record (status: `in_progress`)
4. `PropertyAddress` record
5. `PropertyVerification` record (all flags false)
6. `RoomCategory` records (one per category defined)
7. Individual `Room` records (number_of_rooms per category)
8. Free Trial `Subscription` (5-year expiry)
9. Audit log entry

---

## Verification Checklist

After onboarding, a Super Admin reviews and verifies each field:

| Verification Step | Field Updated |
|------------------|--------------|
| Mobile verified | `property_verifications.mobile_verified` |
| Email verified | `property_verifications.email_verified` |
| PAN verified | `property_verifications.pan_verified` |
| GST verified | `property_verifications.gst_verified` |
| Bank account verified | `property_verifications.bank_verified` |
| Ownership documents verified | `property_verifications.ownership_verified` |
| Legal documents verified | `property_verifications.documents_verified` |
| Property photos verified | `property_verifications.photos_verified` |
| Map location verified | `property_verifications.map_verified` |

**Verification Score** = number of verified fields / total fields × 100

When all fields are verified, `property_verifications.status = "verified"` and `property.onboarding_status = "approved"`.

---

## Mobile App Onboarding Flow

The mobile app has a separate onboarding flow (`features/property_onboarding/`):
1. Staff logs in for the first time.
2. If `onboarding_status != "approved"`, they are redirected to an onboarding pending screen.
3. The app shows the current onboarding progress from `offline-bootstrap` response.
4. Once `onboarding_status = "approved"`, staff gets full access to operational modules.

---

## Onboarding Module Backend

**Router:** `app/modules/onboarding/`

Key endpoints:
- `GET /onboarding/{property_id}/status` — get current onboarding status
- `POST /onboarding/{property_id}/submit` — submit for review
- `PATCH /onboarding/{property_id}/approve` — Super Admin approves

---

## Cross-References

- Property model: [04-database.md#properties](./04-database.md)
- Create property wizard: [07-frontend.md](./07-frontend.md)
- Subscription auto-creation: [12-subscriptions.md](./12-subscriptions.md)
