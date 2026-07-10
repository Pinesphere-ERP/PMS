from fastapi import APIRouter
router = APIRouter()

@router.get("/")
def get_properties():
    return {"status": "properties stub"}
