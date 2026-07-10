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
from app.modules.reports.router import router as reports
from app.modules.settings.router import router as settings
from app.modules.seed.router import router as seed

api_router = APIRouter()
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
api_router.include_router(settings, prefix="/settings", tags=["Settings & Configuration"])
api_router.include_router(seed, prefix="/seed", tags=["Dev: Seed Data"])
