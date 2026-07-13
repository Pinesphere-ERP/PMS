import base64
import os
import aiohttp
from typing import Dict, Any

class OCRService:
    """
    AI OCR Service for ID Scanning during Check-in.
    In production, this would call AWS Textract, Google Cloud Vision, or Azure Form Recognizer.
    """
    def __init__(self):
        self.api_key = os.getenv("OCR_API_KEY")
        
    async def extract_id_details(self, image_bytes: bytes) -> Dict[str, Any]:
        """
        Extract details (Name, DOB, ID Number) from an ID card image.
        """
        if not self.api_key or self.api_key == "dummy_key":
            return {
                "success": False,
                "error": "OCR is not configured explicitly. Missing valid OCR_API_KEY."
            }
            
        return {
            "success": False,
            "error": "Real OCR integration is not implemented yet."
        }

ocr_service = OCRService()
