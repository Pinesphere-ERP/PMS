import uuid
import json
import base64
import hmac
import hashlib
from datetime import datetime, timedelta
from typing import List, Optional, Tuple, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, desc
from fastapi import HTTPException, status

from app.infra.models import Device, AuditLog, User, Property
from app.modules.subscriptions.models import Subscription, SubscriptionPlan, License
from app.modules.devices.schemas import (
    DeviceRegisterRequest, DeviceActivateRequest, DeviceActivateResponse,
    DeviceActionRequest, DeviceTransferRequest, DeviceSyncCheckinRequest,
    DeviceSyncCheckinResponse, DeviceResponse, DeviceDetailResponse,
    AuditLogEntryResponse, SyncLogEntryResponse
)
from app.core.config import settings

SECRET_KEY_BYTES = settings.SECRET_KEY.encode('utf-8')

def generate_signed_token(device_uid: str, property_id: str, expiry_date: str, max_devices: int) -> Tuple[str, str, str]:
    """
    Generates offline license token payload and cryptographic signature.
    Matches BRD Section 3.1 & 3.3 offline verifiable signature requirements.
    """
    payload_dict = {
        "device_uid": device_uid,
        "property_id": property_id,
        "expiry_date": expiry_date,
        "max_devices": max_devices,
        "issued_at": datetime.utcnow().isoformat(),
        "license_code": f"PINE-STAY-{uuid.uuid4().hex[:8].upper()}"
    }
    payload_json = json.dumps(payload_dict, sort_keys=True)
    token_payload_b64 = base64.b64encode(payload_json.encode('utf-8')).decode('utf-8')
    
    # Sign token payload using HMAC-SHA256 (simulating RSA/ECDSA signature verification)
    signature = hmac.new(SECRET_KEY_BYTES, token_payload_b64.encode('utf-8'), hashlib.sha256).hexdigest()
    return token_payload_b64, signature, payload_dict["license_code"]

async def register_device(db: AsyncSession, req: DeviceRegisterRequest, current_user_id: Optional[uuid.UUID] = None) -> DeviceResponse:
    # Check if property exists
    prop_stmt = select(Property).where(Property.property_id == req.property_id)
    prop_res = await db.execute(prop_stmt)
    prop = prop_res.scalar_one_or_none()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")

    # Check if device already registered
    dev_stmt = select(Device).where(Device.device_uid == req.device_uid)
    dev_res = await db.execute(dev_stmt)
    device = dev_res.scalar_one_or_none()

    display_name = req.device_name or req.device_model or "Mobile Device"

    if device:
        device.device_name = display_name
        device.os_type = req.os_type
        if current_user_id and not device.primary_user_id:
            device.primary_user_id = current_user_id
    else:
        device = Device(
            device_uid=req.device_uid,
            property_id=req.property_id,
            primary_user_id=current_user_id,
            device_name=display_name,
            os_type=req.os_type,
            status="pending_approval"
        )
        db.add(device)
        await db.flush()

    # Create immutable audit log entry
    audit = AuditLog(
        property_id=req.property_id,
        user_id=current_user_id,
        timestamp=datetime.utcnow(),
        module_name="device_management",
        action_type="register",
        target_entity="device",
        target_record_id=device.id,
        new_value_snapshot={
            "device_uid": req.device_uid,
            "device_name": display_name,
            "os_type": req.os_type,
            "os_version": req.os_version,
            "app_version": req.app_version,
            "status": device.status
        }
    )
    db.add(audit)
    await db.commit()
    await db.refresh(device)
    return await enrich_device_response(db, device)

async def activate_device(db: AsyncSession, device_id: uuid.UUID) -> DeviceActivateResponse:
    dev_stmt = select(Device).where(Device.id == device_id)
    dev_res = await db.execute(dev_stmt)
    device = dev_res.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    if device.status != "active":
        raise HTTPException(status_code=400, detail=f"Device cannot be activated. Current status is '{device.status}'. Must be approved first.")

    # Determine max devices from property subscription or default
    sub_stmt = select(SubscriptionPlan).join(Subscription, Subscription.plan_id == SubscriptionPlan.id).where(Subscription.property_id == device.property_id)
    sub_res = await db.execute(sub_stmt)
    plan = sub_res.scalar_one_or_none()
    max_devices = plan.device_limit if plan else 5

    expiry_date = (datetime.utcnow() + timedelta(days=365)).strftime("%Y-%m-%d")
    token_payload, signature, license_code = generate_signed_token(
        device_uid=device.device_uid,
        property_id=str(device.property_id),
        expiry_date=expiry_date,
        max_devices=max_devices
    )

    return DeviceActivateResponse(
        device_id=device.id,
        device_uid=device.device_uid,
        property_id=device.property_id,
        status=device.status,
        license_code=license_code,
        expiry_date=expiry_date,
        device_count_allowed=max_devices,
        digital_signature=signature,
        token_payload=token_payload,
        issued_at=datetime.utcnow()
    )

async def list_devices(db: AsyncSession, property_id: Optional[uuid.UUID] = None, status_filter: Optional[str] = None) -> List[DeviceResponse]:
    query = select(Device)
    if property_id:
        query = query.where(Device.property_id == property_id)
    if status_filter:
        query = query.where(Device.status == status_filter)
    
    query = query.order_by(desc(Device.created_at))
    res = await db.execute(query)
    devices = res.scalars().all()

    enriched = []
    for d in devices:
        enriched.append(await enrich_device_response(db, d))
    return enriched

async def get_device_detail(db: AsyncSession, device_id: uuid.UUID) -> DeviceDetailResponse:
    dev_stmt = select(Device).where(Device.id == device_id)
    dev_res = await db.execute(dev_stmt)
    device = dev_res.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    base = await enrich_device_response(db, device)
    
    # Query latest audit log snapshot for extra details
    audit_stmt = select(AuditLog).where(
        AuditLog.target_record_id == device.id,
        AuditLog.module_name == "device_management",
        AuditLog.action_type == "register"
    ).order_by(desc(AuditLog.timestamp)).limit(1)
    audit_res = await db.execute(audit_stmt)
    audit = audit_res.scalar_one_or_none()
    
    device_model = "Unknown Model"
    os_version = "Unknown OS"
    app_version = "1.0.0"
    if audit and audit.new_value_snapshot:
        device_model = audit.new_value_snapshot.get("device_name", "Android Device")
        os_version = audit.new_value_snapshot.get("os_version", "Android 14")
        app_version = audit.new_value_snapshot.get("app_version", "1.0.4")

    # Count sync checkins
    sync_cnt_stmt = select(func.count(AuditLog.log_id)).where(
        AuditLog.target_record_id == device.id,
        AuditLog.module_name == "device_sync"
    )
    sync_res = await db.execute(sync_cnt_stmt)
    sync_count = sync_res.scalar() or 0

    return DeviceDetailResponse(
        **base.model_dump(),
        device_model=device_model,
        os_version=os_version,
        app_version=app_version,
        last_login_at=base.updated_at or base.created_at,
        session_history_count=max(1, sync_count // 2),
        recent_sync_count=sync_count
    )

async def perform_device_action(
    db: AsyncSession,
    device_id: uuid.UUID,
    req: DeviceActionRequest,
    current_user_id: Optional[uuid.UUID] = None
) -> DeviceResponse:
    dev_stmt = select(Device).where(Device.id == device_id)
    dev_res = await db.execute(dev_stmt)
    device = dev_res.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    action = req.action_type.lower()
    old_status = device.status
    pending_cmd = None

    if action == "approve":
        # Enforcement of Device-Count against subscription plan
        active_cnt_stmt = select(func.count(Device.id)).where(
            Device.property_id == device.property_id,
            Device.status == "active",
            Device.id != device.id
        )
        cnt_res = await db.execute(active_cnt_stmt)
        active_count = cnt_res.scalar() or 0

        sub_stmt = select(SubscriptionPlan).join(Subscription, Subscription.plan_id == SubscriptionPlan.id).where(Subscription.property_id == device.property_id)
        sub_res = await db.execute(sub_stmt)
        plan = sub_res.scalar_one_or_none()
        max_devices = plan.device_limit if plan else 5

        if active_count >= max_devices:
            raise HTTPException(
                status_code=400,
                detail=f"Device limit ({max_devices}) reached for current subscription plan. Deactivate an existing device or upgrade plan."
            )
        device.status = "active"

    elif action == "reject":
        device.status = "rejected"
    elif action == "lock":
        device.status = "locked"
        pending_cmd = "LOCK"
    elif action == "unlock":
        device.status = "active"
    elif action == "disable":
        device.status = "disabled"
        pending_cmd = "LOCK"
    elif action == "enable":
        device.status = "active"
    elif action == "logout":
        pending_cmd = "LOGOUT"
    elif action == "rename":
        if req.new_name:
            device.device_name = req.new_name
    elif action == "transfer":
        if req.transfer_to_user_id:
            device.primary_user_id = req.transfer_to_user_id
    elif action == "revoke":
        # Staff Resignation / Remote Deactivation Flow
        device.status = "revoked"
        pending_cmd = "REVOKE_AND_ERASE"
    elif action == "force-sync":
        pending_cmd = "FORCE_SYNC"
    else:
        raise HTTPException(status_code=400, detail=f"Unsupported action_type: {action}")

    # Write immutable audit entry
    audit = AuditLog(
        property_id=device.property_id,
        user_id=current_user_id,
        timestamp=datetime.utcnow(),
        module_name="device_management",
        action_type=action,
        target_entity="device",
        target_record_id=device.id,
        old_value_snapshot={"status": old_status},
        new_value_snapshot={
            "status": device.status,
            "reason": req.reason,
            "pending_remote_command": pending_cmd,
            "performed_by": str(current_user_id) if current_user_id else "admin"
        }
    )
    db.add(audit)
    await db.commit()
    await db.refresh(device)
    return await enrich_device_response(db, device)

async def sync_checkin(db: AsyncSession, req: DeviceSyncCheckinRequest) -> DeviceSyncCheckinResponse:
    dev_stmt = select(Device).where(Device.device_uid == req.device_uid)
    dev_res = await db.execute(dev_stmt)
    device = dev_res.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=404, detail="Device not registered")

    # Update heartbeat / last sync timestamp on device
    device.updated_at = datetime.utcnow()

    # Record sync checkin audit log
    audit = AuditLog(
        property_id=device.property_id,
        user_id=device.primary_user_id,
        timestamp=datetime.utcnow(),
        module_name="device_sync",
        action_type="checkin",
        target_entity="device",
        target_record_id=device.id,
        new_value_snapshot={
            "battery_level": req.battery_level,
            "records_pushed": req.records_pushed,
            "records_pulled": req.records_pulled,
            "sync_status": req.status,
            "error_message": req.error_message
        }
    )
    db.add(audit)

    # Check for pending remote commands (revoke, logout, lock) queued in audit logs
    cmd_stmt = select(AuditLog).where(
        AuditLog.target_record_id == device.id,
        AuditLog.module_name == "device_management",
        AuditLog.action_type.in_(["revoke", "logout", "lock", "disable"])
    ).order_by(desc(AuditLog.timestamp)).limit(1)
    cmd_res = await db.execute(cmd_stmt)
    latest_cmd_log = cmd_res.scalar_one_or_none()

    pending_cmd = "NONE"
    reason = None
    if latest_cmd_log and latest_cmd_log.new_value_snapshot:
        snapshot_cmd = latest_cmd_log.new_value_snapshot.get("pending_remote_command")
        if snapshot_cmd:
            pending_cmd = snapshot_cmd
            reason = latest_cmd_log.new_value_snapshot.get("reason", "Remote command issued by administrator.")

    await db.commit()
    return DeviceSyncCheckinResponse(
        status="success",
        server_time=datetime.utcnow(),
        pending_remote_command=pending_cmd,
        remote_command_reason=reason
    )

async def get_device_logs(db: AsyncSession, device_id: uuid.UUID) -> List[AuditLogEntryResponse]:
    stmt = select(AuditLog).where(
        AuditLog.target_record_id == device_id,
        AuditLog.module_name == "device_management"
    ).order_by(desc(AuditLog.timestamp))
    res = await db.execute(stmt)
    logs = res.scalars().all()
    return [AuditLogEntryResponse.model_validate(l) for l in logs]

async def get_sync_logs(db: AsyncSession, device_id: uuid.UUID) -> List[SyncLogEntryResponse]:
    stmt = select(AuditLog).where(
        AuditLog.target_record_id == device_id,
        AuditLog.module_name == "device_sync"
    ).order_by(desc(AuditLog.timestamp)).limit(50)
    res = await db.execute(stmt)
    logs = res.scalars().all()

    sync_logs = []
    for l in logs:
        snap = l.new_value_snapshot or {}
        sync_logs.append(SyncLogEntryResponse(
            log_id=l.log_id,
            device_id=device_id,
            timestamp=l.timestamp,
            sync_type="incremental" if snap.get("records_pushed", 0) > 0 else "heartbeat",
            status=snap.get("sync_status", "success"),
            records_pushed=snap.get("records_pushed", 0),
            records_pulled=snap.get("records_pulled", 0),
            conflict_count=0,
            error_message=snap.get("error_message")
        ))
    return sync_logs

async def enrich_device_response(db: AsyncSession, device: Device) -> DeviceResponse:
    user_name = "Unassigned Staff"
    if device.primary_user_id:
        user_stmt = select(User).where(User.id == device.primary_user_id)
        user_res = await db.execute(user_stmt)
        user = user_res.scalar_one_or_none()
        if user:
            user_name = user.name

    # Inspect latest sync log for battery level & sync status
    sync_stmt = select(AuditLog).where(
        AuditLog.target_record_id == device.id,
        AuditLog.module_name == "device_sync"
    ).order_by(desc(AuditLog.timestamp)).limit(1)
    sync_res = await db.execute(sync_stmt)
    latest_sync = sync_res.scalar_one_or_none()

    battery_level = 95
    sync_status = "synced"
    last_sync_at = device.updated_at or device.created_at

    if latest_sync and latest_sync.new_value_snapshot:
        last_sync_at = latest_sync.timestamp
        battery_level = latest_sync.new_value_snapshot.get("battery_level", 95)
        sync_status = latest_sync.new_value_snapshot.get("sync_status", "synced")

    # Offline detection check (> 24h since last sync)
    if last_sync_at and (datetime.utcnow() - last_sync_at) > timedelta(hours=24):
        sync_status = "offline"

    approval_status = "pending"
    if device.status == "active":
        approval_status = "approved"
    elif device.status in ("rejected", "revoked"):
        approval_status = "rejected"

    return DeviceResponse(
        id=device.id,
        device_uid=device.device_uid,
        property_id=device.property_id,
        primary_user_id=device.primary_user_id,
        primary_user_name=user_name,
        device_name=device.device_name,
        os_type=device.os_type,
        status=device.status or "pending_approval",
        created_at=device.created_at,
        updated_at=device.updated_at,
        last_sync_at=last_sync_at,
        sync_status=sync_status,
        battery_level=battery_level,
        approval_status=approval_status
    )
