from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any

router = APIRouter()

class MutationPayload(BaseModel):
    id: int
    entity_type: str
    entity_id: int
    operation: str
    payload: Dict[str, Any]
    hlc_timestamp: str

class SyncPushRequest(BaseModel):
    mutations: List[MutationPayload]

@router.post("/push")
async def sync_push(request: SyncPushRequest):
    """
    Receives offline mutations from the mobile app and applies them.
    In a full implementation, this would validate HLCs and insert/update DB.
    """
    # For now, we mock the success response to allow testing the offline-sync loop
    print(f"Received {len(request.mutations)} mutations for sync.")
    for m in request.mutations:
        print(f"Processing {m.operation} on {m.entity_type} {m.entity_id} at {m.hlc_timestamp}")
    
    return {"status": "success", "processed_count": len(request.mutations)}

@router.get("/pull")
async def sync_pull(last_hlc: str):
    """
    Returns mutations that happened on the server since the client's last_hlc.
    """
    return {"mutations": []}
