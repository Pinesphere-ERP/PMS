import aiohttp
import os
from typing import Dict, Any, Optional
from datetime import datetime

class WhatsAppService:
    def __init__(self):
        # In a real app, these would come from settings or env vars
        self.api_url = os.getenv("WHATSAPP_API_URL", "https://graph.facebook.com/v17.0/")
        self.phone_number_id = os.getenv("WHATSAPP_PHONE_NUMBER_ID", "dummy_phone_id")
        self.access_token = os.getenv("WHATSAPP_ACCESS_TOKEN", "dummy_token")

    async def _send_request(self, payload: Dict[str, Any]) -> bool:
        """Helper to send the HTTP request to WhatsApp API"""
        url = f"{self.api_url}{self.phone_number_id}/messages"
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        
        # Log instead of actual HTTP request for this demo/stub
        print(f"📡 [WhatsApp API] Sending to {payload.get('to')}: {payload}")
        return True
        
        # Actual implementation:
        # async with aiohttp.ClientSession() as session:
        #     async with session.post(url, json=payload, headers=headers) as response:
        #         if response.status == 200:
        #             return True
        #         error = await response.text()
        #         print(f"WhatsApp API Error: {error}")
        #         return False

    async def send_booking_confirmation(self, phone_number: str, booking_ref: str, guest_name: str, check_in_date: datetime) -> bool:
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

    async def send_checkout_invoice(self, phone_number: str, guest_name: str, invoice_url: str) -> bool:
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
