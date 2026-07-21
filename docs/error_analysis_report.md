# Error Analysis & Diagnostics Report

**Date:** July 20, 2026  
**Environment:** Frontend Web Application (`pms-bvko.onrender.com`)  
**Context:** Subscription Plan Creation & Inventory Module  

---

## 1. Overview & Summary of Findings

During the action to create a new **Subscription Plan** via the web interface, the application encountered runtime API request failures visible in the browser developer console:

1. **HTTP 400 Bad Request (`POST /subscriptions/plans` or similar endpoint)**: Triggered upon submitting the **Create Subscription Plan** form.
2. **HTTP 404 Not Found (`GET /inventory/rooms`)**: Triggered when attempting to load inventory room resources.
3. **Browser Extension Warnings (`Grammarly.js`)**: Non-critical telemetry warnings caused by third-party browser extensions.

---

## 2. Detailed Error Diagnostics

### Error 1: HTTP 400 Bad Request (Subscription Plan Creation)

| Parameter | Details |
| :--- | :--- |
| **Status Code** | `HTTP 400 Bad Request` |
| **Request URL** | `https://pms-bvko.onrender.com/.../subscriptions/plans` |
| **Trigger Event** | Clicking **"Create Plan"** button |
| **Form Data Submitted** | • **Plan Name:** `premium`<br>• **Features Description:** `dfghjklrtyu`<br>• **Amount (INR):** `₹9999.61`<br>• **Duration (Months):** `1`<br>• **Status:** `Active` |

#### Potential Root Causes for HTTP 400:
1. **Invalid Format for `Amount`**:
   - The input field value contains a currency symbol (`₹9999.61`). If the frontend sends `"₹9999.61"` as a string instead of a sanitized numeric value (`9999.61`), the backend schema validation will reject it (expecting a `number` or `float`).
2. **Enum Value Case Mismatch**:
   - The dropdown selected `Active`. If the backend API validator strictly expects uppercase (`ACTIVE`) or lowercase (`active`), schema validation will fail.
3. **Duplicate Entry**:
   - The plan name `premium` might already exist in the database if uniqueness constraints are enforced on plan names.
4. **Missing Required Fields / Bad Request Payload Structure**:
   - Key mismatch between frontend field names (e.g. `amount`, `duration`, `description`, `status`) and backend DTO schema.

---

### Error 2: HTTP 404 Not Found (Inventory Rooms Endpoint)

| Parameter | Details |
| :--- | :--- |
| **Status Code** | `HTTP 404 Not Found` |
| **Request URL** | `https://pms-bvko.onrender.com/.../inventory/rooms` |
| **Impact** | The application fails to fetch or render room inventory data. |

#### Potential Root Causes for HTTP 404:
1. **Missing or Misconfigured API Route**: The backend endpoint `/api/v1/inventory/rooms` does not exist or has a typo in the URL path on the server.
2. **Backend Deployment / Routing Issue**: Server deployment on Render may be missing the routing layer for inventory modules.

---

### Non-Critical Console Warnings (Browser Extensions)

* **Grammarly Extension Logs**:
  * `[DEFAULT]: WARN : Using DEFAULT root logger`
  * `[Telemetry.TS.AgentExperimentationService]: WARN : Requested gate not found...`
* **Note**: These are standard third-party browser extension logs and do not impact core app functionality.

---

## 3. Recommended Remediation Plan

### Frontend Fixes
1. **Sanitize Amount Input before API Payload Construction**:
   Ensure currency symbols and commas are stripped before posting:
   ```javascript
   // Convert "₹9999.61" -> 9999.61
   const rawAmount = formValues.amount;
   const numericAmount = parseFloat(rawAmount.replace(/[^0-9.]/g, ''));
   ```
2. **Validate Request Payload**:
   Verify network request payload in DevTools **Network Tab** to confirm field keys match backend expectations:
   ```json
   {
     "name": "premium",
     "description": "dfghjklrtyu",
     "amount": 9999.61,
     "durationMonths": 1,
     "status": "ACTIVE"
   }
   ```
3. **Verify API Base URLs & Routes**:
   Ensure `/inventory/rooms` route is correctly configured in environment variables or service API endpoints.

### Backend Fixes
1. Check backend logs on **Render dashboard** (`pms-bvko.onrender.com`) for exact schema validation error messages returned by your API validator (e.g. Zod, Joi, Class-Validator).
2. Confirm route registration for `/inventory/rooms`.
