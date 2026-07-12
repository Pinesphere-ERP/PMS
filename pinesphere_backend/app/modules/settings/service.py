import uuid
from datetime import datetime
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from app.infra.models import SystemConfiguration, PropertySetting
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


# ── System Configuration CRUD ──────────────────────────────────

async def create_system_config(
    db: AsyncSession,
    req: SystemConfigCreateRequest,
    current_user_id: Optional[uuid.UUID] = None,
) -> SystemConfigResponse:
    existing = await db.execute(
        select(SystemConfiguration).where(SystemConfiguration.config_key == req.config_key)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail=f"Config key '{req.config_key}' already exists")

    config = SystemConfiguration(
        config_key=req.config_key,
        config_value=req.config_value,
        description=req.description,
        updated_by=current_user_id,
    )
    db.add(config)
    await db.commit()
    await db.refresh(config)
    return SystemConfigResponse.model_validate(config)


async def list_system_configs(
    db: AsyncSession,
    search: Optional[str] = None,
) -> SystemConfigListResponse:
    query = select(SystemConfiguration)
    count_query = select(func.count(SystemConfiguration.id))

    if search:
        like = f"%{search}%"
        condition = SystemConfiguration.config_key.ilike(like) | SystemConfiguration.description.ilike(like)
        query = query.where(condition)
        count_query = count_query.where(condition)

    query = query.order_by(SystemConfiguration.config_key)
    result = await db.execute(query)
    configs = result.scalars().all()

    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    return SystemConfigListResponse(
        items=[SystemConfigResponse.model_validate(c) for c in configs],
        total=total,
    )


async def get_system_config(db: AsyncSession, config_id: uuid.UUID) -> SystemConfigResponse:
    result = await db.execute(
        select(SystemConfiguration).where(SystemConfiguration.id == config_id)
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail="System configuration not found")
    return SystemConfigResponse.model_validate(config)


async def get_system_config_by_key(db: AsyncSession, config_key: str) -> SystemConfigResponse:
    result = await db.execute(
        select(SystemConfiguration).where(SystemConfiguration.config_key == config_key)
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail=f"Config key '{config_key}' not found")
    return SystemConfigResponse.model_validate(config)


async def update_system_config(
    db: AsyncSession,
    config_id: uuid.UUID,
    req: SystemConfigUpdateRequest,
    current_user_id: Optional[uuid.UUID] = None,
) -> SystemConfigResponse:
    result = await db.execute(
        select(SystemConfiguration).where(SystemConfiguration.id == config_id)
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail="System configuration not found")

    config.config_value = req.config_value
    if req.description is not None:
        config.description = req.description
    config.updated_by = current_user_id
    config.updated_at = datetime.utcnow()

    await db.commit()
    await db.refresh(config)
    return SystemConfigResponse.model_validate(config)


async def delete_system_config(db: AsyncSession, config_id: uuid.UUID) -> None:
    result = await db.execute(
        select(SystemConfiguration).where(SystemConfiguration.id == config_id)
    )
    config = result.scalar_one_or_none()
    if not config:
        raise HTTPException(status_code=404, detail="System configuration not found")
    await db.delete(config)
    await db.commit()


# ── Property Setting CRUD ──────────────────────────────────────

async def create_property_setting(
    db: AsyncSession,
    property_id: uuid.UUID,
    req: PropertySettingCreateRequest,
    current_user_id: Optional[uuid.UUID] = None,
    device_id: Optional[str] = None,
) -> PropertySettingResponse:
    existing = await db.execute(
        select(PropertySetting).where(
            and_(
                PropertySetting.property_id == property_id,
                PropertySetting.setting_key == req.setting_key,
                PropertySetting.is_deleted == False,
            )
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=409,
            detail=f"Setting key '{req.setting_key}' already exists for this property",
        )

    setting = PropertySetting(
        property_id=property_id,
        setting_key=req.setting_key,
        setting_value=req.setting_value,
        value_type=req.value_type,
        description=req.description,
        updated_by=current_user_id,
        device_id=device_id,
    )
    db.add(setting)
    await db.commit()
    await db.refresh(setting)
    return PropertySettingResponse.model_validate(setting)


async def list_property_settings(
    db: AsyncSession,
    property_id: uuid.UUID,
    search: Optional[str] = None,
) -> PropertySettingListResponse:
    base = and_(
        PropertySetting.property_id == property_id,
        PropertySetting.is_deleted == False,
    )
    query = select(PropertySetting).where(base)
    count_query = select(func.count(PropertySetting.id)).where(base)

    if search:
        like = f"%{search}%"
        search_cond = PropertySetting.setting_key.ilike(like) | PropertySetting.description.ilike(like)
        query = query.where(search_cond)
        count_query = count_query.where(search_cond)

    query = query.order_by(PropertySetting.setting_key)
    result = await db.execute(query)
    settings = result.scalars().all()

    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    return PropertySettingListResponse(
        items=[PropertySettingResponse.model_validate(s) for s in settings],
        total=total,
    )


async def get_property_setting(
    db: AsyncSession,
    property_id: uuid.UUID,
    setting_id: uuid.UUID,
) -> PropertySettingResponse:
    result = await db.execute(
        select(PropertySetting).where(
            and_(
                PropertySetting.id == setting_id,
                PropertySetting.property_id == property_id,
                PropertySetting.is_deleted == False,
            )
        )
    )
    setting = result.scalar_one_or_none()
    if not setting:
        raise HTTPException(status_code=404, detail="Property setting not found")
    return PropertySettingResponse.model_validate(setting)


async def get_property_setting_by_key(
    db: AsyncSession,
    property_id: uuid.UUID,
    setting_key: str,
) -> Optional[PropertySettingResponse]:
    result = await db.execute(
        select(PropertySetting).where(
            and_(
                PropertySetting.property_id == property_id,
                PropertySetting.setting_key == setting_key,
                PropertySetting.is_deleted == False,
            )
        )
    )
    setting = result.scalar_one_or_none()
    if setting:
        return PropertySettingResponse.model_validate(setting)
    return None


async def update_property_setting(
    db: AsyncSession,
    property_id: uuid.UUID,
    setting_id: uuid.UUID,
    req: PropertySettingUpdateRequest,
    current_user_id: Optional[uuid.UUID] = None,
    device_id: Optional[str] = None,
) -> PropertySettingResponse:
    result = await db.execute(
        select(PropertySetting).where(
            and_(
                PropertySetting.id == setting_id,
                PropertySetting.property_id == property_id,
                PropertySetting.is_deleted == False,
            )
        )
    )
    setting = result.scalar_one_or_none()
    if not setting:
        raise HTTPException(status_code=404, detail="Property setting not found")

    setting.setting_value = req.setting_value
    if req.value_type is not None:
        setting.value_type = req.value_type
    if req.description is not None:
        setting.description = req.description
    setting.updated_by = current_user_id
    setting.device_id = device_id
    setting.version += 1
    setting.updated_at = datetime.utcnow()

    await db.commit()
    await db.refresh(setting)
    return PropertySettingResponse.model_validate(setting)


async def delete_property_setting(
    db: AsyncSession,
    property_id: uuid.UUID,
    setting_id: uuid.UUID,
    current_user_id: Optional[uuid.UUID] = None,
    device_id: Optional[str] = None,
) -> None:
    result = await db.execute(
        select(PropertySetting).where(
            and_(
                PropertySetting.id == setting_id,
                PropertySetting.property_id == property_id,
                PropertySetting.is_deleted == False,
            )
        )
    )
    setting = result.scalar_one_or_none()
    if not setting:
        raise HTTPException(status_code=404, detail="Property setting not found")

    setting.is_deleted = True
    setting.deleted_at = datetime.utcnow()
    setting.updated_by = current_user_id
    setting.device_id = device_id
    setting.version += 1

    await db.commit()


async def bulk_upsert_property_settings(
    db: AsyncSession,
    property_id: uuid.UUID,
    req: PropertySettingBulkUpdateRequest,
    current_user_id: Optional[uuid.UUID] = None,
    device_id: Optional[str] = None,
) -> PropertySettingListResponse:
    results = []
    for item in req.settings:
        existing = await db.execute(
            select(PropertySetting).where(
                and_(
                    PropertySetting.property_id == property_id,
                    PropertySetting.setting_key == item.setting_key,
                    PropertySetting.is_deleted == False,
                )
            )
        )
        setting = existing.scalar_one_or_none()
        if setting:
            setting.setting_value = item.setting_value
            setting.value_type = item.value_type
            if item.description is not None:
                setting.description = item.description
            setting.updated_by = current_user_id
            setting.device_id = device_id
            setting.version += 1
            setting.updated_at = datetime.utcnow()
        else:
            setting = PropertySetting(
                property_id=property_id,
                setting_key=item.setting_key,
                setting_value=item.setting_value,
                value_type=item.value_type,
                description=item.description,
                updated_by=current_user_id,
                device_id=device_id,
            )
            db.add(setting)
        results.append(setting)

    await db.commit()
    for s in results:
        await db.refresh(s)

    return PropertySettingListResponse(
        items=[PropertySettingResponse.model_validate(s) for s in results],
        total=len(results),
    )
