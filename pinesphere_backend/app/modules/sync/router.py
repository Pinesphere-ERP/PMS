from fastapi import APIRouter
router = APIRouter()

@router.get("/")
def get_sync():
    return {"status": "sync stub"}
