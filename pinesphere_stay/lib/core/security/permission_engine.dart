enum UserRole {
  superAdmin,
  owner,
  manager,
  reception,
  housekeeping,
  accountant,
  guest
}

enum PermissionModule {
  propertyOnboarding,
  subscriptionManagement,
  userManagement,
  deviceManagement,
  roomManagement,
  bookingManagement,
  checkIn,
  payments,
  reports,
  auditLogs,
}

enum PermissionAction {
  none,
  view,
  limited,
  updateStatus,
  createManageOwn,
  collect,
  financial,
  ownActions,
  full,
}

class PermissionEngine {
  static const Map<UserRole, Map<PermissionModule, PermissionAction>> _matrix = {
    UserRole.superAdmin: {
      PermissionModule.propertyOnboarding: PermissionAction.full,
      PermissionModule.subscriptionManagement: PermissionAction.full,
      PermissionModule.userManagement: PermissionAction.full,
      PermissionModule.deviceManagement: PermissionAction.full,
      PermissionModule.roomManagement: PermissionAction.full,
      PermissionModule.bookingManagement: PermissionAction.full,
      PermissionModule.checkIn: PermissionAction.full,
      PermissionModule.payments: PermissionAction.full,
      PermissionModule.reports: PermissionAction.full,
      PermissionModule.auditLogs: PermissionAction.full,
    },
    UserRole.owner: {
      PermissionModule.propertyOnboarding: PermissionAction.none,
      PermissionModule.subscriptionManagement: PermissionAction.view,
      PermissionModule.userManagement: PermissionAction.full,
      PermissionModule.deviceManagement: PermissionAction.full,
      PermissionModule.roomManagement: PermissionAction.full,
      PermissionModule.bookingManagement: PermissionAction.full,
      PermissionModule.checkIn: PermissionAction.full,
      PermissionModule.payments: PermissionAction.full,
      PermissionModule.reports: PermissionAction.full,
      PermissionModule.auditLogs: PermissionAction.limited,
    },
    UserRole.manager: {
      PermissionModule.propertyOnboarding: PermissionAction.none,
      PermissionModule.subscriptionManagement: PermissionAction.none,
      PermissionModule.userManagement: PermissionAction.limited,
      PermissionModule.deviceManagement: PermissionAction.view,
      PermissionModule.roomManagement: PermissionAction.full,
      PermissionModule.bookingManagement: PermissionAction.full,
      PermissionModule.checkIn: PermissionAction.full,
      PermissionModule.payments: PermissionAction.limited,
      PermissionModule.reports: PermissionAction.full,
      PermissionModule.auditLogs: PermissionAction.view,
    },
    UserRole.reception: {
      PermissionModule.propertyOnboarding: PermissionAction.none,
      PermissionModule.subscriptionManagement: PermissionAction.none,
      PermissionModule.userManagement: PermissionAction.none,
      PermissionModule.deviceManagement: PermissionAction.none,
      PermissionModule.roomManagement: PermissionAction.view,
      PermissionModule.bookingManagement: PermissionAction.createManageOwn,
      PermissionModule.checkIn: PermissionAction.full,
      PermissionModule.payments: PermissionAction.collect,
      PermissionModule.reports: PermissionAction.none,
      PermissionModule.auditLogs: PermissionAction.none,
    },
    UserRole.housekeeping: {
      PermissionModule.propertyOnboarding: PermissionAction.none,
      PermissionModule.subscriptionManagement: PermissionAction.none,
      PermissionModule.userManagement: PermissionAction.none,
      PermissionModule.deviceManagement: PermissionAction.none,
      PermissionModule.roomManagement: PermissionAction.updateStatus,
      PermissionModule.bookingManagement: PermissionAction.none,
      PermissionModule.checkIn: PermissionAction.none,
      PermissionModule.payments: PermissionAction.none,
      PermissionModule.reports: PermissionAction.none,
      PermissionModule.auditLogs: PermissionAction.none,
    },
    UserRole.accountant: {
      PermissionModule.propertyOnboarding: PermissionAction.none,
      PermissionModule.subscriptionManagement: PermissionAction.none,
      PermissionModule.userManagement: PermissionAction.none,
      PermissionModule.deviceManagement: PermissionAction.none,
      PermissionModule.roomManagement: PermissionAction.none,
      PermissionModule.bookingManagement: PermissionAction.view,
      PermissionModule.checkIn: PermissionAction.none,
      PermissionModule.payments: PermissionAction.financial,
      PermissionModule.reports: PermissionAction.financial,
      PermissionModule.auditLogs: PermissionAction.limited,
    },
    UserRole.guest: {
      PermissionModule.propertyOnboarding: PermissionAction.none,
      PermissionModule.subscriptionManagement: PermissionAction.none,
      PermissionModule.userManagement: PermissionAction.none,
      PermissionModule.deviceManagement: PermissionAction.none,
      PermissionModule.roomManagement: PermissionAction.none,
      PermissionModule.bookingManagement: PermissionAction.ownActions,
      PermissionModule.checkIn: PermissionAction.ownActions,
      PermissionModule.payments: PermissionAction.ownActions,
      PermissionModule.reports: PermissionAction.none,
      PermissionModule.auditLogs: PermissionAction.limited,
    },
  };

  /// Check if a user role has the required action permission on a specific module.
  /// Handles hierarchical permissions (e.g., 'full' implies 'view', 'updateStatus', etc).
  static bool hasPermission(UserRole role, PermissionModule module, PermissionAction requiredAction) {
    final allowedAction = _matrix[role]?[module] ?? PermissionAction.none;

    if (allowedAction == PermissionAction.full) return true;
    if (requiredAction == PermissionAction.none) return true;
    
    // Exact match
    if (allowedAction == requiredAction) return true;

    // View is subset of almost everything else except none
    if (requiredAction == PermissionAction.view && allowedAction != PermissionAction.none) {
      return true;
    }

    return false;
  }
}
