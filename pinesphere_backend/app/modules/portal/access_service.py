from typing import Optional, Dict
from datetime import datetime, timezone, timedelta
from app.infra.models import Booking, CheckIn, CheckOut

class PortalAccessService:
    GRACE_WINDOW_HOURS = 24

    @classmethod
    def _is_checked_in(cls, booking: Optional[Booking], checkin: Optional[CheckIn]) -> bool:
        if not booking or not checkin:
            return False
        return booking.booking_status == "checked_in" and checkin.status == "active"

    @classmethod
    def _is_in_grace_window(cls, checkout: Optional[CheckOut]) -> bool:
        if not checkout or not checkout.checkout_time:
            return False
        now = datetime.now(timezone.utc)
        # Ensure checkout_time is timezone-aware
        ct = checkout.checkout_time
        if ct.tzinfo is None:
            ct = ct.replace(tzinfo=timezone.utc)
        return (now - ct) <= timedelta(hours=cls.GRACE_WINDOW_HOURS)

    @classmethod
    def can_login(cls, booking: Optional[Booking], checkin: Optional[CheckIn], checkout: Optional[CheckOut]) -> bool:
        if cls._is_checked_in(booking, checkin):
            return True
        if booking and booking.booking_status == "completed" and cls._is_in_grace_window(checkout):
            return True
        return False

    @classmethod
    def can_view_dashboard(cls, booking: Optional[Booking], checkin: Optional[CheckIn], checkout: Optional[CheckOut]) -> bool:
        return cls.can_login(booking, checkin, checkout)

    @classmethod
    def can_request_service(cls, booking: Optional[Booking], checkin: Optional[CheckIn]) -> bool:
        return cls._is_checked_in(booking, checkin)

    @classmethod
    def can_pay(cls, booking: Optional[Booking], checkin: Optional[CheckIn], checkout: Optional[CheckOut]) -> bool:
        return cls.can_login(booking, checkin, checkout)

    @classmethod
    def can_download_invoice(cls, booking: Optional[Booking], checkin: Optional[CheckIn], checkout: Optional[CheckOut]) -> bool:
        return cls.can_login(booking, checkin, checkout)

    @classmethod
    def can_submit_feedback(cls, booking: Optional[Booking], checkin: Optional[CheckIn], checkout: Optional[CheckOut]) -> bool:
        return cls.can_login(booking, checkin, checkout)

    @classmethod
    def should_revoke(cls, booking: Optional[Booking], checkin: Optional[CheckIn], checkout: Optional[CheckOut]) -> bool:
        if not booking:
            return True
        if booking.booking_status in ["cancelled", "no_show"]:
            return True
        if booking.booking_status == "completed" and not cls._is_in_grace_window(checkout):
            return True
        return False

    @classmethod
    def get_capabilities(cls, booking: Optional[Booking], checkin: Optional[CheckIn], checkout: Optional[CheckOut]) -> Dict[str, bool]:
        return {
            "can_login": cls.can_login(booking, checkin, checkout),
            "can_view_dashboard": cls.can_view_dashboard(booking, checkin, checkout),
            "can_request_service": cls.can_request_service(booking, checkin),
            "can_pay": cls.can_pay(booking, checkin, checkout),
            "can_download_invoice": cls.can_download_invoice(booking, checkin, checkout),
            "can_submit_feedback": cls.can_submit_feedback(booking, checkin, checkout),
            "should_revoke": cls.should_revoke(booking, checkin, checkout)
        }
