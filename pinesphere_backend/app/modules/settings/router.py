import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.dependencies import require_property_access, require_super_admin

from app.infra.database import get_db
from app.modules.settings import service
from app.modules.settings.schemas import (
    SystemConfigCreateRequest,
    SystemConfigUpdateRequest,
    SystemConfigResponse,
    SystemConfigListResponse,
    PropertySettingCreateRequest,
    PropertySettingUpdateRequest,
    PropertySettingResponse,
    PropertySettingListResponse,
    PropertySettingBulkUpdateRequest,
)

router = APIRouter()


# ── System Configuration Endpoints ─────────────────────────────

@router.post(
    "/system",
    response_model=SystemConfigResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_super_admin)],
)
async def create_system_config(
    req: SystemConfigCreateRequest,
    db: AsyncSession = Depends(get_db),
):
    return await service.create_system_config(db, req)


@router.get("/system", response_model=SystemConfigListResponse, dependencies=[Depends(require_super_admin)])
async def list_system_configs(
    search: Optional[str] = Query(None, description="Search by key or description"),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_system_configs(db, search=search)


@router.get("/system/{config_id}", response_model=SystemConfigResponse, dependencies=[Depends(require_super_admin)])
async def get_system_config(
    config_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    return await service.get_system_config(db, config_id)


@router.get("/system/by-key/{config_key}", response_model=SystemConfigResponse, dependencies=[Depends(require_super_admin)])
async def get_system_config_by_key(
    config_key: str,
    db: AsyncSession = Depends(get_db),
):
    return await service.get_system_config_by_key(db, config_key)


@router.patch("/system/{config_id}", response_model=SystemConfigResponse, dependencies=[Depends(require_super_admin)])
async def update_system_config(
    config_id: uuid.UUID,
    req: SystemConfigUpdateRequest,
    db: AsyncSession = Depends(get_db),
):
    return await service.update_system_config(db, config_id, req)


@router.delete("/system/{config_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(require_super_admin)])
async def delete_system_config(
    config_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    await service.delete_system_config(db, config_id)


# ── Property Setting Endpoints ─────────────────────────────────

@router.post(
    "/property/{property_id}",
    response_model=PropertySettingResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_property_access)]
)
async def create_property_setting(
    property_id: uuid.UUID,
    req: PropertySettingCreateRequest,
    db: AsyncSession = Depends(get_db),
):
    return await service.create_property_setting(db, property_id, req)


@router.get("/property/{property_id}", response_model=PropertySettingListResponse, dependencies=[Depends(require_property_access)])
async def list_property_settings(
    property_id: uuid.UUID,
    search: Optional[str] = Query(None, description="Search by key or description"),
    db: AsyncSession = Depends(get_db),
):
    return await service.list_property_settings(db, property_id, search=search)


@router.get("/property/{property_id}/{setting_id}", response_model=PropertySettingResponse, dependencies=[Depends(require_property_access)])
async def get_property_setting(
    property_id: uuid.UUID,
    setting_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    return await service.get_property_setting(db, property_id, setting_id)


@router.get("/property/{property_id}/by-key/{setting_key}", response_model=Optional[PropertySettingResponse], dependencies=[Depends(require_property_access)])
async def get_property_setting_by_key(
    property_id: uuid.UUID,
    setting_key: str,
    db: AsyncSession = Depends(get_db),
):
    result = await service.get_property_setting_by_key(db, property_id, setting_key)
    if not result:
        raise HTTPException(status_code=404, detail=f"Setting '{setting_key}' not found for this property")
    return result


@router.patch("/property/{property_id}/{setting_id}", response_model=PropertySettingResponse, dependencies=[Depends(require_property_access)])
async def update_property_setting(
    property_id: uuid.UUID,
    setting_id: uuid.UUID,
    req: PropertySettingUpdateRequest,
    db: AsyncSession = Depends(get_db),
):
    return await service.update_property_setting(db, property_id, setting_id, req)


@router.delete("/property/{property_id}/{setting_id}", status_code=status.HTTP_204_NO_CONTENT, dependencies=[Depends(require_property_access)])
async def delete_property_setting(
    property_id: uuid.UUID,
    setting_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    await service.delete_property_setting(db, property_id, setting_id)


@router.post(
    "/property/{property_id}/bulk",
    response_model=PropertySettingListResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(require_property_access)]
)
async def bulk_upsert_property_settings(
    property_id: uuid.UUID,
    req: PropertySettingBulkUpdateRequest,
    db: AsyncSession = Depends(get_db),
):
    return await service.bulk_upsert_property_settings(db, property_id, req)
