# Manager Frontend Development Agent

## Objective

Implement the complete **Manager Frontend Module** by integrating the already completed Manager Backend APIs.

The backend is production-ready. The frontend should **consume existing APIs only** and must **not implement business logic locally**. All validations, permissions, workflows, notifications, and audit logging are handled by the backend.

The objective is to build a modern, responsive, offline-capable Manager application that follows the Pinesphere Stay PRD.

---

# Current Backend Status

The backend implementation is complete.

Implemented features include:

- Dashboard
- Staff Management
- Attendance
- Performance
- Shift Management
- Task Assignment
- Booking Oversight
- Check-in Monitoring
- Room Readiness
- Housekeeping Dispatch
- Maintenance
- Reports
- Manager Notes
- Daily Checklist
- Room Blocks
- Notifications
- Audit Logging

Frontend should consume these APIs.

Do NOT recreate backend logic.

---

# Responsibilities

The Manager is responsible for operational management only.

Manager can:

- View operational dashboard
- Monitor bookings
- Modify bookings
- Confirm bookings
- Monitor check-ins/check-outs
- Assign housekeeping
- Assign maintenance
- Assign laundry
- Monitor staff attendance
- View staff performance
- Schedule shifts
- View reports
- Manage room blocks
- Manage manager notes
- Complete daily checklists

Manager CANNOT

- View payments
- View financial reports
- Manage subscriptions
- Change property settings
- Create users
- Delete users
- Manage permissions
- Access Super Admin features

Never expose Owner-only features.

---

# Architecture

Follow clean architecture.

UI

↓

State Management

↓

Repository

↓

API Service

↓

Backend

No business logic inside widgets.

No direct API calls from UI.

Repositories should be the only layer communicating with the backend.

---

# Folder Structure

manager/

    screens/

    widgets/

    models/

    providers/

    repository/

    services/

    routes/

    utils/

Keep every feature isolated.

---

# State Management

Each feature should have its own provider/controller.

Recommended providers

DashboardProvider

StaffProvider

AttendanceProvider

PerformanceProvider

ShiftProvider

BookingProvider

CheckinProvider

HousekeepingProvider

MaintenanceProvider

ReportsProvider

RoomBlockProvider

NotesProvider

ChecklistProvider

NotificationProvider

Avoid one large provider.

---

# Dashboard

Consume

GET /manager/dashboard

Display

- Occupancy
- Today's Arrivals
- Today's Departures
- Active Tasks
- Pending Requests
- Maintenance Summary
- Cleaning Summary
- Staff Availability
- Room Blocks

Do NOT display

- Revenue
- Payments
- GST
- Financial Reports

Dashboard should support

- Pull to refresh
- Auto refresh
- Loading skeletons
- Empty state
- Error state

---

# Staff Management

Consume existing APIs.

Features

- Staff List
- Attendance
- Performance
- Shift Schedule
- Assign Task

Task Assignment

Use backend validation.

Do not validate

- active shift
- role matching
- cross property

inside Flutter.

Backend already handles this.

Display backend errors properly.

---

# Booking Module

Support

- Booking List
- Booking Detail
- Edit Booking
- Confirm Booking
- Change Room

Never expose

- Cancel Booking
- Refund
- Payment Editing

Use backend validation only.

---

# Check-in Monitoring

Display

- Live Check-ins
- Live Check-outs
- Room Readiness

Support

- Search
- Filters
- Refresh

No editing.

---

# Housekeeping

Features

- View Tasks
- Assign Task
- Reassign Task
- Inspect Task
- Close Task

Workflow is controlled by backend.

Display task status timeline.

Never manually update room status.

Backend controls room availability.

---

# Maintenance

Features

- Ticket List
- Ticket Detail
- Create Ticket
- Assign Technician
- Update Status
- Close Ticket

Display

Priority

Status

Assigned Technician

Timeline

Room

Backend controls room release.

---

# Reports

Consume

Operational

Occupancy

Housekeeping

Maintenance

Staff Performance

Display charts where appropriate.

Support

Date filters

Refresh

Pagination

Do not calculate reports locally.

---

# Manager Notes

Support

- List
- Create
- Edit
- Pin
- Resolve

Use backend endpoints.

---

# Daily Checklist

Display

Checklist Items

Progress

Completion Percentage

Sign-off Status

History

---

# Room Blocks

Support

- List
- Create
- Release

Display

Reason

Date Range

Blocked By

Room

---

# Notifications

Integrate existing notification APIs.

Display

Assignment Notifications

Maintenance Notifications

Cleaning Notifications

Room Block Notifications

Service Request Notifications

Support badge count.

---

# UI Guidelines

Use existing design system.

Maintain consistency with Owner Module.

Every screen should support

Loading

Success

Empty

Error

Retry

Confirmation Dialog

Search

Pagination

Filtering

Responsive Layout

Dark Mode

Accessibility

---

# Offline

Frontend must support offline mode.

Cache previously loaded data where applicable.

Queue user actions using the existing sync architecture.

Never bypass backend conflict resolution.

---

# Error Handling

Never hide backend errors.

Display meaningful messages.

Handle

401

403

404

409

422

500

gracefully.

---

# Security

Never expose

Owner APIs

Financial APIs

Subscription APIs

User Management APIs

Permission APIs

Respect backend RBAC.

Hide unauthorized actions.

---

# Performance

Use pagination.

Lazy load long lists.

Avoid rebuilding entire screens.

Cache dashboard data.

Minimize unnecessary API requests.

---

# Testing Checklist

Verify

Dashboard

Staff

Attendance

Performance

Shift Schedule

Task Assignment

Booking

Check-ins

Housekeeping

Maintenance

Reports

Notes

Checklist

Room Blocks

Notifications

Offline

Role Restrictions

Responsive Layout

Dark Mode

API Integration

---

# Completion Criteria

The frontend is complete when:

- Every Manager backend endpoint is integrated.
- Every Manager screen is functional.
- No Owner-only functionality is visible.
- Backend validations are respected.
- All loading, empty, and error states are implemented.
- Offline support works with the existing sync mechanism.
- UI is responsive across supported devices.
- The complete Manager operational workflow can be performed without requiring the Owner.