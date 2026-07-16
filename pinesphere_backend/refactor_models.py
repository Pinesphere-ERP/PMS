import re

with open("app/infra/models.py", "r") as f:
    content = f.read()

# 1. Add schema="public" to Platform models
platform_models = [
    "Owner", "Business", "Property", "Role", "Permission", "RolePermission",
    "User", "UserPropertyAccess", "Device", "UserDevice", "UserSession",
    "StaffInvitation", "CredentialResetRequest", "UserSyncLog",
    "SubscriptionPlan", "Subscription", "SubscriptionTransaction", "PendingDue"
]

for model in platform_models:
    # Find __table_args__ = {'extend_existing': True}
    # Or __table_args__ = (..., {'extend_existing': True})
    
    # Simple regex replacement for the class definition
    pattern = r'(class ' + model + r'\b.*?__table_args__ = )(\{.*?\})'
    
    def repl(m):
        args = m.group(2)
        if "'schema'" not in args:
            args = args.replace('}', ", 'schema': 'public'}")
        return m.group(1) + args
        
    content = re.sub(pattern, repl, content, flags=re.DOTALL)
    
    pattern2 = r'(class ' + model + r'\b.*?__table_args__ = \([^)]*?)(\{.*?\})(\n?\s*\))'
    def repl2(m):
        args = m.group(2)
        if "'schema'" not in args:
            args = args.replace('}', ", 'schema': 'public'}")
        return m.group(1) + args + m.group(3)
        
    content = re.sub(pattern2, repl2, content, flags=re.DOTALL)

# 2. Remove property_id from Tenant models
tenant_models = [
    "RoomCategory", "Room", "Guest", "Booking", "CheckIn", "CheckOut",
    "Invoice", "AuditLog", "HousekeepingTask", "MaintenanceTicket", "LostAndFound"
]

for model in tenant_models:
    # Find the class block
    pattern = r'(class ' + model + r'\b.*?)(?=\nclass |\Z)'
    match = re.search(pattern, content, flags=re.DOTALL)
    if match:
        class_body = match.group(1)
        # Remove property_id line
        class_body = re.sub(r'\n\s+property_id: Mapped.*?ForeignKey\("properties\.property_id"\).*?\n', '\n', class_body)
        class_body = re.sub(r'\n\s+property_id: Mapped.*?ForeignKey\("properties\.property_id".*?\).*?\n', '\n', class_body)
        # Remove from index in __table_args__ if any (e.g. AuditLog)
        class_body = class_body.replace('"ix_audit_logs_property_timestamp", "property_id", "timestamp"', '"ix_audit_logs_timestamp", "timestamp"')
        
        content = content[:match.start()] + class_body + content[match.end():]

with open("app/infra/models_refactored.py", "w") as f:
    f.write(content)

print("Refactored models written to app/infra/models_refactored.py")
