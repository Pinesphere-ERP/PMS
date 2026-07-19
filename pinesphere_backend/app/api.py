from fastapi import APIRouter
from app.modules.auth import router as auth
from app.modules.sync import router as sync
from app.modules.properties import router as property
from app.modules.subscriptions import router as subscription
from app.modules.devices import router as devices
from app.modules.payments.router import router as payments
from app.modules.bookings import router as bookings
from app.modules.checkin import router as checkin
from app.modules.checkout import router as checkout
from app.modules.housekeeping import router as housekeeping
from app.modules.staff.router import router as staff
from app.modules.reports.router import router as reports
from app.modules.settings.router import router as settings
from app.modules.audit.router import router as audit
from app.modules.users.router import router as users
from app.modules.guests.router import router as guests
from app.modules.tasks.router import router as tasks
from app.modules.notifications.router import router as notifications
from app.modules.portal.router import router as portal
from app.modules.onboarding.router import router as onboarding

# ── New modules (Wave 5–9 completions) ────────────────────────────────────────
from app.modules.pricing.router import router as pricing
from app.modules.documents.router import router as documents
from app.modules.broker.router import router as broker
from app.modules.security.router import router as security
from app.modules.security_guard.router import router as security_guard
from app.modules.manager.router import router as manager
from app.modules.accountant.router import router as accountant

api_router = APIRouter()

# ── Core ──────────────────────────────────────────────────────────────────────
api_router.include_router(auth, prefix="/auth", tags=["Authentication"])
api_router.include_router(sync, prefix="/sync", tags=["Sync Engine"])
api_router.include_router(property, prefix="/properties", tags=["Property Management"])
api_router.include_router(subscription, prefix="/subscriptions", tags=["Subscription Management"])
api_router.include_router(devices, prefix="/devices", tags=["Device Management"])
api_router.include_router(payments, prefix="/payments", tags=["Payments"])
api_router.include_router(bookings, prefix="/bookings", tags=["Booking Management"])
api_router.include_router(checkin, prefix="/checkin", tags=["Check-In Management"])
api_router.include_router(checkout, prefix="/checkout", tags=["Check-Out Management"])
api_router.include_router(housekeeping, prefix="/housekeeping", tags=["Housekeeping & Maintenance"])
api_router.include_router(reports, prefix="/reports", tags=["Reports & Analytics"])
api_router.include_router(staff)
api_router.include_router(settings, prefix="/settings", tags=["Settings & Configuration"])
api_router.include_router(audit, prefix="/audit", tags=["Audit Logs"])
api_router.include_router(users, prefix="/users", tags=["User Management"])
api_router.include_router(guests, prefix="/guests", tags=["Guest Management"])
api_router.include_router(tasks, prefix="/tasks", tags=["Shared Tasks"])
api_router.include_router(notifications, prefix="/notifications", tags=["Notifications"])
api_router.include_router(portal)  # Portal has its own prefix="/portal"
api_router.include_router(onboarding, prefix="/onboarding", tags=["Onboarding"])

# ── Phase 6: Dynamic Pricing ──────────────────────────────────────────────────
api_router.include_router(pricing, prefix="/pricing", tags=["Dynamic Pricing"])

# ── Phase 8: Foreign Guest Compliance (Form C / FRRO) ─────────────────────────
api_router.include_router(documents, prefix="/documents", tags=["Foreign Guest Compliance"])

# ── Phase 9: Broker Commission Engine ────────────────────────────────────────
api_router.include_router(broker, prefix="/broker", tags=["Broker Commission"])

# ── Phase 7: Security Dashboard ──────────────────────────────────────────────
api_router.include_router(security, prefix="/security", tags=["Security Management"])

# ── Phase 10: Staff Role Modules ─────────────────────────────────────────────
api_router.include_router(security_guard, prefix="/guard", tags=["Security Guard"])
api_router.include_router(manager, prefix="/manager", tags=["Manager Operations"])
api_router.include_router(accountant, prefix="/accountant", tags=["Accountant Operations"])
