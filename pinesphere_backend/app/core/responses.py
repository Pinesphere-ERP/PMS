from typing import TypeVar, Generic, Optional, Any
from pydantic import BaseModel, Field

T = TypeVar("T")

class Pagination(BaseModel):
    total: int
    page: int
    size: int
    pages: int

class MetaData(BaseModel):
    timestamp: Optional[str] = None
    requestId: Optional[str] = None

class StandardResponse(BaseModel, Generic[T]):
    success: bool = True
    message: str = "Success"
    data: Optional[T] = None
    pagination: Optional[Pagination] = None
    meta: Optional[MetaData] = None

def success_response(data: Any = None, message: str = "Success", pagination: Optional[Pagination] = None, meta: Optional[MetaData] = None) -> StandardResponse:
    return StandardResponse(
        success=True,
        message=message,
        data=data,
        pagination=pagination,
        meta=meta
    )

def error_response(message: str, data: Any = None, meta: Optional[MetaData] = None) -> StandardResponse:
    return StandardResponse(
        success=False,
        message=message,
        data=data,
        meta=meta
    )
