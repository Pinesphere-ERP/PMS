# 14. Booking Flow (End-to-End)

## Overview

The complete guest lifecycle from booking to check-out.

```
[Create Guest] -> [Create Booking] -> [Check-In] -> [Stay] -> [Check-Out] -> [Invoice]
```

---

## Step 1: Create Guest

**Who:** Receptionist or Manager

**API:** `POST /bookings/guests`

**Data required:**
- `property_id` — the property
- `full_name` — guest's full name
- `mobile` — phone number (optional but recommended)
- `email` — email (optional)

**Backend logic:**
1. Validates `property_id` access.
2. Creates `Guest` record in DB.
3. Returns `guest_id`.

**Returning guest:** Check if guest already exists with `GET /bookings/guests?search=<name_or_mobile>` before creating.

---

## Step 2: Create Booking

**Who:** Receptionist

**API:** `POST /bookings`

**Data required:**
```json
{
  "property_id": "uuid",
  "room_id": "uuid",
  "guest_id": "uuid",
  "check_in_date": "2026-07-25",
  "check_out_date": "2026-07-28",
  "adults": 2,
  "children": 0,
  "room_rent": 5000.00,
  "deposit": 2000.00,
  "discount": 0.00,
  "taxes": 900.00,
  "total_payable": 5900.00,
  "advance_paid": 2000.00,
  "pending_amount": 3900.00,
  "booking_type": "walkin",
  "booking_source": "direct",
  "notes": "Anniversary"
}
```

**Backend Logic:**

1. Assert `property_id` access.
2. **Availability Check:**
   ```sql
   SELECT COUNT(*) FROM bookings
   WHERE room_id = :room_id
   AND booking_status IN ('confirmed', 'checked_in')
   AND check_in_date < :check_out_date
   AND check_out_date > :check_in_date
   ```
   If count > 0: returns `409 Conflict`.
3. Generate `booking_reference` (format: `PSY-<YEAR>-<SEQ>`).
4. Create `Booking` record.
5. Return booking detail.

**Dynamic Pricing:**
If pricing rules are configured for the property, the booking amount may be auto-adjusted by the Pricing Rules Engine before the final `total_payable` is calculated.

---

## Step 3: Check-In

**Who:** Receptionist

**API:** `POST /checkin/{booking_id}`

**Request:**
```json
{
  "deposit": 2000,
  "advance_paid": 2000,
  "id_verified": true,
  "special_requests": "Late checkout requested"
}
```

**Backend Logic:**
1. Find `Booking` by `booking_id`.
2. Assert property access.
3. Create `CheckIn` record:
   - `checked_in_at = now()`
   - `status = "active"`
4. Update `Booking.booking_status = "checked_in"`.
5. Update `Room.occupancy_status = "occupied"`.
6. **Foreign Guest Check:** If guest has a foreign nationality document, auto-generate `FormCRecord` with `deadline_at = now() + 24h`.
7. **WhatsApp:** Send welcome message to guest's mobile.
8. **Audit Log:** Log the check-in event.
9. Return `CheckIn` record.

**ID Verification:**
The `id_verified` flag indicates receptionist has physically seen and verified the guest's ID document. The system does not perform automated OCR verification at check-in (that is a separate process for Form C compliance).

---

## Step 4: During Stay

While the guest is checked in, multiple operations happen:

### Room Service Requests
Guest (via portal) or staff submits service requests:
```
POST /portal/service-request or POST /tasks
```
- Creates `ServiceRequest` or `Task` record.
- Assigns to appropriate staff.
- Sends in-app notification to assigned staff.

### F&B Orders
Kitchen staff logs food orders:
```
POST /kitchen/orders { room_id, items: [...] }
```
- Creates `FolioLineItem` with `category = "food"`.

### Housekeeping
Housekeeping staff updates room status throughout the day:
```
PATCH /housekeeping/rooms/{room_id}/status { clean_status: "cleaning" }
```

### Maintenance
If a maintenance issue is found:
```
POST /housekeeping/maintenance { room_id, category, issue_description, priority }
```

### Folio (Live Bill)
The folio accumulates all charges:
```
GET /checkout/{booking_id}/folio
```
Returns all `FolioLineItem` records for the booking.

---

## Step 5: Check-Out

**Who:** Receptionist or Manager

**API:** `POST /checkout/{booking_id}`

**Request:**
```json
{
  "total_amount": 15900.00,
  "advance_paid": 2000.00,
  "remaining_balance": 13900.00,
  "payment_status": "paid",
  "payment_mode": "upi",
  "payment_reference": "UPI-TX-001"
}
```

**Backend Logic:**
1. Find active `CheckIn` for this booking.
2. Calculate final folio total (sum all `FolioLineItem`s for this booking).
3. Create `CheckOut` record.
4. Update `Booking.booking_status = "checked_out"`.
5. Update `Room.occupancy_status = "vacant"`.
6. Update `Room.housekeeping_status = "dirty"` (needs cleaning for next guest).
7. Create `Payment` record for the final payment.
8. Generate `Invoice` with `InvoiceItem`s:
   - Room charge (per night × nights)
   - F&B charges (from folio)
   - Service charges
   - Tax / GST
9. **WhatsApp:** Send checkout thank-you + bill summary to guest.
10. **Audit Log:** Log the checkout event.
11. Return checkout detail + invoice.

---

## Step 6: Invoice

**Generated at:** Check-out

**Structure:**
```
Invoice #PSY-INV-2024-001
Property: Grand Hotel
Date: 2026-07-28

Guest: Alice Smith
Room: 101 (Deluxe) - 3 Nights

Line Items:
  Room Charges (3 × ₹5,000)    ₹15,000
  Restaurant (Room 101)         ₹2,500
  Laundry                       ₹500
  GST (18%)                     ₹3,240
  Discount                     -₹1,000
  ─────────────────────────────────────
  Total                        ₹20,240
  Advance Paid                 -₹2,000
  ─────────────────────────────────────
  Balance Due                  ₹18,240
```

**PDF Generation:**
- Backend generates PDF using ReportLab or generates a URL.
- Mobile app can also generate PDF using `pdf` Dart package.
- Invoice PDF URL is sent in WhatsApp message.

---

## Booking Status Transitions

```
                 [confirmed]
                     |
              Check-In processed
                     |
                     v
                [checked_in]
                     |
              Check-Out processed
                     |
                     v
               [checked_out]

[confirmed] ----cancel----> [cancelled]
```

---

## Room Status Transitions

```
           [vacant] ------booking-----> [reserved]
              |                              |
              |                         check-in
              |                              |
              |                              v
              |                         [occupied]
              |                              |
              |                         check-out
              |                              |
              |                              v
              <-----------clean---------[dirty]
                                           |
                                      cleaning start
                                           |
                                           v
                                      [cleaning]
                                           |
                                      cleaning done
                                           |
                                           v
                                       [clean]
                                           |
                                       ready for
                                       next guest
```

---

## Broker Booking Flow

When `booking_source = "broker"`:
1. `broker_user_id` must be set to the broker's user ID.
2. On booking creation, the system looks up `BrokerCommissionRule` for this broker + property.
3. Commission is calculated: `commission = room_rent × rate_percent / 100`.
4. `CommissionTransaction` is created.
5. `BrokerWallet.balance` is updated.
6. Broker can view their wallet via `GET /broker/wallet/{broker_user_id}`.
7. Manager can initiate payout via `POST /broker/payout`.

---

## Foreign Guest Compliance

When guest has foreign nationality:
1. At check-in, `FormCRecord` is auto-created with:
   - `status = "generated"`
   - `deadline_at = check_in_time + 24 hours`
2. Receptionist uploads guest's passport/visa details via `POST /documents/nationality`.
3. `FormCRecord.status` updated to `"submitted"` when submission is done.
4. PDF is generated and stored at `pdf_url`.
5. Manager receives reminder notification if form not submitted within 20 hours.

---

## Multi-Room Bookings

**Current limitation:** One booking = one room. Each room requires a separate booking record.

**Workaround:** Create multiple bookings for the same guest for different rooms on the same dates.

---

## Cross-References

- Booking API: [06-api-reference.md](./06-api-reference.md)
- Room model: [04-database.md#rooms](./04-database.md)
- Pricing rules: [05-backend.md](./05-backend.md)
- WhatsApp notifications: [11-notifications.md](./11-notifications.md)
