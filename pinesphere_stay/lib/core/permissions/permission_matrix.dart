import 'user_role.dart';

enum Module {
  propertyOnboarding,
  subscriptionManagement,
  userRoleManagement,
  deviceManagement,
  roomManagement,
  bookingManagement,
  checkInCheckOut,
  payments,
  reports,
  auditLogs,
  settings,
  guestManagement,
  staffManagement,
  housekeeping,
  dashboard,
  serviceRequests
}

enum AccessLevel {
  none,
  view,
  limited,
  updateStatus,
  collect,
  full,
}

class PermissionMatrix {
  static AccessLevel getAccessLevel(UserRole role, Module module) {
    // Super Admin has full access to everything except where noted differently in the matrix
    if (role == UserRole.superAdmin) return AccessLevel.full;

    switch (module) {
      case Module.propertyOnboarding:
        return AccessLevel.none; // Only SuperAdmin
        
      case Module.subscriptionManagement:
        if (role == UserRole.owner) return AccessLevel.view; // View/Renew
        return AccessLevel.none;

      case Module.userRoleManagement:
        if (role == UserRole.owner) return AccessLevel.full;
        if (role == UserRole.manager) return AccessLevel.limited;
        return AccessLevel.none;

      case Module.deviceManagement:
        if (role == UserRole.owner) return AccessLevel.full;
        if (role == UserRole.manager) return AccessLevel.view;
        return AccessLevel.none;

      case Module.roomManagement:
        if (role == UserRole.owner) return AccessLevel.full;
        if (role == UserRole.manager) return AccessLevel.full;
        if (role == UserRole.reception) return AccessLevel.limited;
        if (role == UserRole.housekeeping) return AccessLevel.updateStatus;
        if (role == UserRole.guest) return AccessLevel.view;
        return AccessLevel.none;

      case Module.bookingManagement:
        if (role == UserRole.owner) return AccessLevel.full;
        if (role == UserRole.manager) return AccessLevel.full;
        if (role == UserRole.reception) return AccessLevel.full;
        if (role == UserRole.accountant) return AccessLevel.view;
        if (role == UserRole.guest) return AccessLevel.limited; // Create/Manage Own
        return AccessLevel.none;

      case Module.checkInCheckOut:
        if (role == UserRole.owner) return AccessLevel.full;
        if (role == UserRole.manager) return AccessLevel.full;
        if (role == UserRole.reception) return AccessLevel.full;
        if (role == UserRole.accountant) return AccessLevel.view;
        if (role == UserRole.guest) return AccessLevel.limited; // Digital Check-in
        return AccessLevel.none;

      case Module.payments:
        if (role == UserRole.owner) return AccessLevel.full;
        if (role == UserRole.manager) return AccessLevel.limited;
        if (role == UserRole.reception) return AccessLevel.collect;
        if (role == UserRole.accountant) return AccessLevel.full;
        if (role == UserRole.guest) return AccessLevel.limited; // Pay Online
        return AccessLevel.none;

      case Module.reports:
        if (role == UserRole.owner) return AccessLevel.full;
        if (role == UserRole.manager) return AccessLevel.limited; // Operational
        if (role == UserRole.reception) return AccessLevel.limited;
        if (role == UserRole.accountant) return AccessLevel.limited; // Financial
        return AccessLevel.none;

      case Module.auditLogs:
        if (role == UserRole.owner) return AccessLevel.full; // Property Only
        if (role == UserRole.manager) return AccessLevel.limited;
        if (role == UserRole.reception) return AccessLevel.limited; // Own Actions
        if (role == UserRole.housekeeping) return AccessLevel.limited; // Own Actions
        if (role == UserRole.accountant) return AccessLevel.limited; // Financial
        return AccessLevel.none;
        
      case Module.serviceRequests:
        if (role == UserRole.owner || role == UserRole.manager) return AccessLevel.full;
        if (role == UserRole.reception || role == UserRole.housekeeping) return AccessLevel.limited;
        if (role == UserRole.guest) return AccessLevel.view;
        return AccessLevel.none;

      case Module.dashboard:
        // Assume everyone can view a personalized dashboard
        return AccessLevel.view;
        
      case Module.housekeeping:
        if (role == UserRole.owner || role == UserRole.manager || role == UserRole.housekeeping) return AccessLevel.full;
        return AccessLevel.none;

      case Module.staffManagement:
        if (role == UserRole.owner) return AccessLevel.full;
        if (role == UserRole.manager) return AccessLevel.limited;
        return AccessLevel.none;

      case Module.guestManagement:
        if (role == UserRole.owner || role == UserRole.manager || role == UserRole.reception) return AccessLevel.full;
        if (role == UserRole.guest) return AccessLevel.limited;
        return AccessLevel.none;

      case Module.settings:
        if (role == UserRole.owner || role == UserRole.manager) return AccessLevel.full;
        if (role == UserRole.reception) return AccessLevel.view;
        return AccessLevel.none;
    }
  }

  static bool hasAccess(UserRole role, Module module) {
    return getAccessLevel(role, module) != AccessLevel.none;
  }
}
