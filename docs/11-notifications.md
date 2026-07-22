# 11. Notification System

## Overview

Pinesphere Stay delivers notifications through multiple channels:
- **WhatsApp** — automated messages for guests (check-in welcome, check-out summary)
- **In-App** — notifications stored in the `notifications` table, displayed in the mobile app
- **Push Notifications** — FCM (Firebase Cloud Messaging) — **Partially Implemented**
- **Email** — **Not Implemented**
- **SMS** — **Not Implemented**

---

## WhatsApp Notifications

**File:** `pinesphere_backend/app/core/notifications.py`

**Service:** `WhatsAppService` class (singleton `whatsapp` instance)

**API:** WhatsApp Business Cloud API (Meta)

**Required env vars:**
```
WHATSAPP_API_URL=https://graph.facebook.com/v18.0/
WHATSAPP_PHONE_NUMBER_ID=<your_phone_number_id>
WHATSAPP_ACCESS_TOKEN=<your_access_token>
```

If these vars are not configured, the service **logs the message to console** with `[WhatsApp Notification Mock]` prefix. The system continues working — WhatsApp is non-critical.

### Triggered Messages

#### 1. Check-In Welcome Message
**Triggered by:** `POST /checkin/{booking_id}`

**Recipient:** Guest's registered mobile number

**Content includes:**
```
🌴 Welcome to {property_name}!

Dear {guest_name},
Your check-in is complete! Here are your stay details:

• Room Number: {room_number}
• Check-in Date: {check_in_date}
• Check-out Date: {check_out_date}

📱 Guest Management Portal:
{portal_url}

You can log in to your portal anytime using your registered mobile number ({phone_number}) 
to control room amenities, request services, and view your bill.

Enjoy your stay!
```

**Why text format instead of template?**
WhatsApp Business API requires template approval for outbound messages to non-opted-in users. Text messages are sent to users who have previously messaged the business number. The current implementation uses text messages (guests who have booked directly via WhatsApp integration).

#### 2. Check-Out Thank-You Message
**Triggered by:** `POST /checkout/{booking_id}`

**Recipient:** Guest's registered mobile number

**Content includes:**
```
🙏 Thank You for Staying at {property_name}!

Dear {guest_name},
We hope you had a wonderful stay in Room {room_number}.

🧾 Billing & Payment Summary:
• Room Charges: ₹{room_charges}
• Food & Dining: ₹{restaurant_charges}
• Extra Services: ₹{other_charges}
• Taxes / GST: ₹{taxes}
-------------------------------
• Total Amount: ₹{total_amount}
• Total Paid: ₹{total_paid}
• Balance Due: ₹{balance_due}

📄 Download Digital Receipt / Invoice:
{invoice_url}

We look forward to welcoming you back soon! Safe travels!
```

#### 3. Booking Confirmation (Template)
**Triggered by:** Booking creation (if enabled)

Uses WhatsApp template message format:
```json
{
  "template": {
    "name": "booking_confirmation",
    "language": { "code": "en" },
    "components": [{
      "type": "body",
      "parameters": [
        { "type": "text", "text": "{guest_name}" },
        { "type": "text", "text": "{booking_ref}" },
        { "type": "text", "text": "{check_in_date}" }
      ]
    }]
  }
}
```

**Note:** Template must be pre-approved by Meta.

#### 4. Checkout Invoice (Template)
Template name: `checkout_invoice`

---

## In-App Notifications

### Storage
Stored in `notifications` table (see [04-database.md](./04-database.md)).

### Service
**File:** `app/modules/notifications/service.py`

**Dispatch Function:**
```python
async def dispatch_notification(
    db: AsyncSession,
    recipient_id: uuid.UUID,
    title: str,
    message: str,
    channel: str = "in_app",
    priority: str = "normal",
    payload: dict = None
):
    notification = Notification(
        recipient_id=recipient_id,
        title=title,
        message=message,
        channel=channel,
        priority=priority,
        payload=payload
    )
    db.add(notification)
    await db.commit()
```

This is called by `NotificationDispatchService` which is injected into auth and other modules.

### Mobile Notification Feed
The mobile app polls `GET /notifications?status=unread` to display the notification badge count and feed.

**Polling interval:** On app foreground resume (not background).

### Notification Types

| Type | Trigger | Recipients |
|------|---------|-----------|
| New Task Assigned | Task created with `assigned_to` | Assigned staff |
| Task Completed | Task status -> completed | Manager |
| New Booking | Booking created | Property Manager |
| Check-In | Check-in processed | Manager + Owner |
| Check-Out | Check-out processed | Manager + Owner |
| Maintenance Reported | Maintenance ticket created | Manager |
| Low Inventory | (Future) Inventory threshold | Manager |
| Subscription Expiring | (Future) 7 days before expiry | Owner |

---

## Push Notifications (Partially Implemented)

**Status:** Architecture exists but FCM is not connected.

**Planned flow:**
1. Flutter app registers FCM token on login.
2. Token stored in `devices` table (`fcm_token` field — not yet in model).
3. Backend sends FCM push via HTTP to `https://fcm.googleapis.com/v1/...`.
4. Flutter `FirebaseMessaging.onMessage` handler shows local notification.

**To complete implementation:**
1. Add `fcm_token` column to `devices` table.
2. Create `FIREBASE_SERVER_KEY` env var.
3. Add push dispatch to `NotificationDispatchService`.
4. Add `firebase_messaging` dependency to Flutter pubspec.

---

## Notification Flow Example: Task Assignment

```
Manager assigns housekeeping task to staff member
          |
          v
PATCH /tasks/{task_id} { assigned_to: "staff_user_id" }
          |
          v
task service.py updates Task.assigned_to
          |
          v
NotificationDispatchService.dispatch(
    recipient_id = staff_user_id,
    title = "New Task Assigned",
    message = "Clean Room 101 - Priority: High",
    channel = "in_app",
    payload = { "task_id": "uuid", "room_number": "101" }
)
          |
          v
INSERT INTO notifications (...)
          |
          v
Staff member opens mobile app -> notification badge shows
          |
          v
GET /notifications -> returns new notification
          |
          v
Staff taps notification -> navigates to task detail
```

---

## Cross-References

- Backend notifications module: [05-backend.md](./05-backend.md)
- Database table: [04-database.md#notifications](./04-database.md)
- Mobile notification feed: [08-mobile.md](./08-mobile.md)
