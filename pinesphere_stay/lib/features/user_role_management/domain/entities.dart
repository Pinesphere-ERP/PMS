import 'package:objectbox/objectbox.dart';

@Entity()
class UserEntity {
  int id;

  @Unique()
  String serverId;

  String? propertyId;
  String roleId;
  String name;
  String? mobileNumber;
  String? email;
  String? username;
  String? passwordHash;
  String? pinHash;
  bool biometricEnabled;
  bool isPrimaryOwner;
  String status;
  int failedLoginAttempts;
  String? profilePhotoUrl;
  String? createdBy;
  bool isPendingSync;

  UserEntity({
    this.id = 0,
    required this.serverId,
    this.propertyId,
    required this.roleId,
    required this.name,
    this.mobileNumber,
    this.email,
    this.username,
    this.passwordHash,
    this.pinHash,
    this.biometricEnabled = false,
    this.isPrimaryOwner = false,
    this.status = 'ACTIVE',
    this.failedLoginAttempts = 0,
    this.profilePhotoUrl,
    this.createdBy,
    this.isPendingSync = false,
  });
}

@Entity()
class RoleEntity {
  int id;

  @Unique()
  String serverId;

  String? propertyId;
  String roleCode;
  String roleName;
  bool isSystemRole;
  String? description;

  RoleEntity({
    this.id = 0,
    required this.serverId,
    this.propertyId,
    required this.roleCode,
    required this.roleName,
    this.isSystemRole = true,
    this.description,
  });
}

@Entity()
class PermissionEntity {
  int id;

  @Unique()
  String serverId;

  @Unique()
  String permissionCode;
  String moduleName;
  String? description;

  PermissionEntity({
    this.id = 0,
    required this.serverId,
    required this.permissionCode,
    required this.moduleName,
    this.description,
  });
}

@Entity()
class RolePermissionEntity {
  int id;

  @Unique()
  String serverId;

  String roleId;
  String permissionId;
  String accessLevel;

  RolePermissionEntity({
    this.id = 0,
    required this.serverId,
    required this.roleId,
    required this.permissionId,
    required this.accessLevel,
  });
}

@Entity()
class UserSessionEntity {
  int id;

  @Unique()
  String serverId;

  String userId;
  String deviceId;
  String sessionToken;
  bool isOfflineSession;
  
  @Property(type: PropertyType.date)
  DateTime issuedAt;

  @Property(type: PropertyType.date)
  DateTime expiresAt;

  @Property(type: PropertyType.date)
  DateTime? revokedAt;
  
  String? revokedReason;

  UserSessionEntity({
    this.id = 0,
    required this.serverId,
    required this.userId,
    required this.deviceId,
    required this.sessionToken,
    this.isOfflineSession = false,
    required this.issuedAt,
    required this.expiresAt,
    this.revokedAt,
    this.revokedReason,
  });
}

@Entity()
class StaffInvitationEntity {
  int id;

  @Unique()
  String serverId;

  String propertyId;
  String roleId;
  String invitedBy;
  String mobileNumber;
  String invitationToken;
  String status;

  @Property(type: PropertyType.date)
  DateTime expiresAt;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  StaffInvitationEntity({
    this.id = 0,
    required this.serverId,
    required this.propertyId,
    required this.roleId,
    required this.invitedBy,
    required this.mobileNumber,
    required this.invitationToken,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });
}

@Entity()
class UserSyncLogEntity {
  int id;

  @Unique()
  String serverId;

  String entityType;
  String entityId;
  String operation;
  String payloadJson;
  String syncStatus;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime? syncedAt;

  UserSyncLogEntity({
    this.id = 0,
    required this.serverId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.syncStatus,
    required this.createdAt,
    this.syncedAt,
  });
}
