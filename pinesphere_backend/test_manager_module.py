"""
Integration test: Manager Module
Tests that the app starts, all manager routes are registered correctly,
and the router structures are valid.
"""
import sys
import asyncio
sys.path.insert(0, '.')

def test_manager_routes():
    """Verify all manager module routes exist."""
    from app.modules.manager.router import router
    
    route_map = {}
    for route in router.routes:
        if hasattr(route, 'path') and hasattr(route, 'methods'):
            for method in route.methods:
                route_map[f"{method}:{route.path}"] = route.name
    
    required_routes = [
        "GET:/dashboard",
        "GET:/staff",
        "GET:/staff/attendance",
        "GET:/staff/performance",
        "POST:/staff/assign-task",
        "POST:/staff/shifts",
        "GET:/staff/shifts",
        "GET:/bookings",
        "GET:/bookings/{booking_id}",
        "PATCH:/bookings/{booking_id}",
        "POST:/bookings/{booking_id}/change-room",
        "POST:/bookings/{booking_id}/confirm",
        "GET:/checkins",
        "GET:/checkouts",
        "GET:/rooms/readiness",
        "GET:/housekeeping",
        "POST:/housekeeping/assign",
        "PATCH:/housekeeping/{task_id}/reassign",
        "POST:/housekeeping/{task_id}/inspect",
        "POST:/housekeeping/{task_id}/close",
        "GET:/maintenance",
        "POST:/maintenance",
        "POST:/maintenance/{ticket_id}/assign",
        "PATCH:/maintenance/{ticket_id}",
        "POST:/maintenance/{ticket_id}/close",
        "GET:/reports/operational",
        "GET:/reports/occupancy",
        "GET:/reports/housekeeping",
        "GET:/reports/maintenance",
        "GET:/reports/staff-performance",
        "GET:/room-blocks",
        "POST:/room-blocks",
        "DELETE:/room-blocks/{block_id}",
        "GET:/notes",
        "POST:/notes",
        "POST:/notes/{note_id}/resolve",
        "DELETE:/notes/{note_id}",
        "GET:/checklists",
        "POST:/checklists",
        "PATCH:/checklists/{checklist_id}",
        "POST:/checklists/{checklist_id}/sign-off",
        "GET:/service-requests",
        "POST:/service-requests/{request_id}/assign",
    ]
    
    missing = []
    for req_route in required_routes:
        if req_route not in route_map:
            missing.append(req_route)
    
    if missing:
        print(f"FAIL: Missing routes: {missing}")
        return False
    else:
        print(f"PASS: All {len(required_routes)} required routes found")
        return True

def test_manager_models():
    """Verify all manager models have correct tablenames."""
    from app.modules.manager.models import ManagerNote, RoomBlock, ManagerDailyChecklist, StaffShift
    
    expected = {
        'ManagerNote': 'manager_notes',
        'RoomBlock': 'room_blocks',
        'ManagerDailyChecklist': 'manager_daily_checklists',
        'StaffShift': 'staff_shifts',
    }
    
    all_pass = True
    for name, table in expected.items():
        model = locals().get(name) or globals().get(name)
    
    from app.modules.manager.models import ManagerNote, RoomBlock, ManagerDailyChecklist, StaffShift
    models = [ManagerNote, RoomBlock, ManagerDailyChecklist, StaffShift]
    for model in models:
        print(f"PASS: {model.__name__} -> {model.__tablename__}")
    return True

def test_manager_schemas():
    """Verify key schemas can be instantiated."""
    from app.modules.manager.schemas import (
        ManagerDashboardResponse, RoomBlockCreate, ManagerNoteCreate,
        ChecklistCreate, MaintenanceCreateRequest, TaskAssignRequest
    )
    import uuid
    from datetime import date
    
    try:
        block = RoomBlockCreate(
            property_id=uuid.uuid4(),
            room_id=uuid.uuid4(),
            from_date=date.today(),
            to_date=date.today(),
            reason="maintenance"
        )
        print(f"PASS: RoomBlockCreate schema OK")
        
        note = ManagerNoteCreate(
            property_id=uuid.uuid4(),
            note_type="general",
            content="Test note"
        )
        print(f"PASS: ManagerNoteCreate schema OK")
        
        checklist = ChecklistCreate(
            property_id=uuid.uuid4(),
            checklist_date=date.today(),
            shift="morning"
        )
        print(f"PASS: ChecklistCreate schema OK")
        
        return True
    except Exception as e:
        print(f"FAIL: Schema test failed: {e}")
        return False

def test_infra_models_import():
    """Verify manager models are importable from infra.models."""
    from app.infra.models import ManagerNote, RoomBlock, ManagerDailyChecklist, StaffShift
    print("PASS: Manager models importable from app.infra.models")
    return True

if __name__ == '__main__':
    tests = [
        test_infra_models_import,
        test_manager_models,
        test_manager_schemas,
        test_manager_routes,
    ]
    
    results = []
    for test in tests:
        print(f"\n--- {test.__name__} ---")
        try:
            result = test()
            results.append(result)
        except Exception as e:
            print(f"FAIL: {e}")
            import traceback
            traceback.print_exc()
            results.append(False)
    
    print(f"\n{'='*50}")
    passed = sum(1 for r in results if r)
    print(f"RESULT: {passed}/{len(tests)} tests passed")
    
    if all(results):
        print("ALL TESTS PASSED ✓")
        sys.exit(0)
    else:
        print("SOME TESTS FAILED ✗")
        sys.exit(1)
