import aiohttp
import os
from typing import Dict, Any, Optional
from datetime import datetime

class WhatsAppService:
    def __init__(self):
        self.api_url = os.getenv("WHATSAPP_API_URL")
        self.phone_number_id = os.getenv("WHATSAPP_PHONE_NUMBER_ID")
        self.access_token = os.getenv("WHATSAPP_ACCESS_TOKEN")

    async def _send_request(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """Helper to send the HTTP request to WhatsApp API"""
        if not self.api_url or not self.phone_number_id or not self.access_token:
            return {"success": False, "error": "WhatsApp API credentials not configured"}
            
        url = f"{self.api_url}{self.phone_number_id}/messages"
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload, headers=headers) as response:
                if 200 <= response.status < 300:
                    return {"success": True}
                error = await response.text()
                return {"success": False, "error": error}

    async def send_booking_confirmation(self, phone_number: str, booking_ref: str, guest_name: str, check_in_date: datetime) -> Dict[str, Any]:
        """Send a WhatsApp booking confirmation template message"""
        payload = {
            "messaging_product": "whatsapp",
            "to": phone_number,
            "type": "template",
            "template": {
                "name": "booking_confirmation",
                "language": {"code": "en"},
                "components": [
                    {
                        "type": "body",
                        "parameters": [
                            {"type": "text", "text": guest_name},
                            {"type": "text", "text": booking_ref},
                            {"type": "text", "text": check_in_date.strftime("%Y-%m-%d")}
                        ]
                    }
                ]
            }
        }
        return await self._send_request(payload)

    async def send_checkout_invoice(self, phone_number: str, guest_name: str, invoice_url: str) -> Dict[str, Any]:
        """Send a WhatsApp message with the checkout invoice"""
        payload = {
            "messaging_product": "whatsapp",
            "to": phone_number,
            "type": "template",
            "template": {
                "name": "checkout_invoice",
                "language": {"code": "en"},
                "components": [
                    {
                        "type": "body",
                        "parameters": [
                            {"type": "text", "text": guest_name},
                            {"type": "text", "text": invoice_url}
                        ]
                    }
                ]
            }
        }
        return await self._send_request(payload)

    async def send_checkin_welcome_message(
        self,
        phone_number: str,
        guest_name: str,
        room_number: str,
        property_name: str,
        check_in_date: str,
        check_out_date: str,
        portal_url: str = "http://localhost:3000",
    ) -> Dict[str, Any]:
        """Send automated WhatsApp message on check-in with Guest Management URL & login instructions."""
        text_message = (
            f"🌴 *Welcome to {property_name}!*\n\n"
            f"Dear {guest_name},\n"
            f"Your check-in is complete! Here are your stay details:\n\n"
            f"• *Room Number*: {room_number}\n"
            f"• *Check-in Date*: {check_in_date}\n"
            f"• *Check-out Date*: {check_out_date}\n\n"
            f"📱 *Guest Management Portal*:\n"
            f"{portal_url}\n\n"
            f"You can log in to your portal anytime using your registered mobile number ({phone_number}) "
            f"to control room amenities, request services, and view your bill.\n\n"
            f"Enjoy your stay!"
        )

        if not self.api_url or not self.phone_number_id or not self.access_token:
            print(f"[WhatsApp Notification Mock -> Check-In to {phone_number}]:\n{text_message}\n")
            return {"success": True, "mock": True}

        payload = {
            "messaging_product": "whatsapp",
            "to": phone_number,
            "type": "text",
            "text": {"body": text_message},
        }
        return await self._send_request(payload)

    async def send_checkout_thankyou_message(
        self,
        phone_number: str,
        guest_name: str,
        property_name: str,
        room_number: str,
        room_charges: float,
        restaurant_charges: float,
        other_charges: float,
        taxes: float,
        total_amount: float,
        total_paid: float,
        invoice_url: str = "http://localhost:3000/invoice",
    ) -> Dict[str, Any]:
        """Send automated WhatsApp message on check-out with thank-you & full payment summary."""
        balance_due = max(total_amount - total_paid, 0.0)
        text_message = (
            f"🙏 *Thank You for Staying at {property_name}!*\n\n"
            f"Dear {guest_name},\n"
            f"We hope you had a wonderful stay in Room {room_number}.\n\n"
            f"🧾 *Billing & Payment Summary*:\n"
            f"• Room Charges: ₹{room_charges:.2f}\n"
            f"• Food & Dining: ₹{restaurant_charges:.2f}\n"
            f"• Extra Services: ₹{other_charges:.2f}\n"
            f"• Taxes / GST: ₹{taxes:.2f}\n"
            f"-------------------------------\n"
            f"• *Total Amount*: ₹{total_amount:.2f}\n"
            f"• *Total Paid*: ₹{total_paid:.2f}\n"
            f"• *Balance Due*: ₹{balance_due:.2f}\n\n"
            f"📄 *Download Digital Receipt / Invoice*:\n"
            f"{invoice_url}\n\n"
            f"We look forward to welcoming you back soon! Safe travels!"
        )

        if not self.api_url or not self.phone_number_id or not self.access_token:
            print(f"[WhatsApp Notification Mock -> Check-Out to {phone_number}]:\n{text_message}\n")
            return {"success": True, "mock": True}

        payload = {
            "messaging_product": "whatsapp",
            "to": phone_number,
            "type": "text",
            "text": {"body": text_message},
        }
        return await self._send_request(payload)

# Singleton instance to be used across the app
whatsapp = WhatsAppService()

