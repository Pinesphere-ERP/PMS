from fastapi import APIRouter
router = APIRouter()

@router.get("/")
def get_subscriptions():
    return {"status": "subscriptions stub"}
