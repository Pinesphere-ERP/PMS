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

# Singleton instance to be used across the app
whatsapp = WhatsAppService()
