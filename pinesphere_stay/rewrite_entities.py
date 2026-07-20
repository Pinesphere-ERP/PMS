import re

with open('lib/features/user_role_management/domain/entities.dart', 'r') as f:
    content = f.read()

sync_fields = """
  // --- Standard Sync Metadata ---
  String? tenantId;
  @Property(type: PropertyType.date)
  DateTime? createdAt;
  @Property(type: PropertyType.date)
  DateTime? updatedAt;
  @Property(type: PropertyType.date)
  DateTime? lastSyncedAt;
  int syncVersion;
  String? deviceId;
  String? lastModifiedHlc;
  String syncStatus;
  bool isDeleted;
  @Property(type: PropertyType.date)
  DateTime? deletedAt;
  // ------------------------------
"""

sync_constructor_args = """
    this.tenantId,
    this.createdAt,
    this.updatedAt,
    this.lastSyncedAt,
    this.syncVersion = 0,
    this.deviceId,
    this.lastModifiedHlc,
    this.syncStatus = 'Pending',
    this.isDeleted = false,
    this.deletedAt,
"""

entities_to_update = ['UserEntity', 'RoleEntity', 'PermissionEntity', 'RolePermissionEntity']

for entity in entities_to_update:
    # Find class block
    class_pattern = r"(class " + entity + r" \{.*?)(  " + entity + r"\(\{)"
    
    def repl(m):
        return m.group(1) + sync_fields + m.group(2) + sync_constructor_args
        
    content = re.sub(class_pattern, repl, content, flags=re.DOTALL)

with open('lib/features/user_role_management/domain/entities.dart', 'w') as f:
    f.write(content)

