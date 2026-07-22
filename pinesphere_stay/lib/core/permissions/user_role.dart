enum UserRole {
  superAdmin,
  owner,
  manager,
  reception,
  housekeeping,
  kitchen,
  accountant,
  guest;

  String get displayName {
    switch (this) {
      case UserRole.superAdmin: return 'Super Admin';
      case UserRole.owner: return 'Owner';
      case UserRole.manager: return 'Manager';
      case UserRole.reception: return 'Reception';
      case UserRole.housekeeping: return 'Housekeeping';
      case UserRole.kitchen: return 'Kitchen';
      case UserRole.accountant: return 'Accountant';
      case UserRole.guest: return 'Guest';
    }
  }

  static UserRole fromString(String role) {
    final cleanRole = role.trim().toLowerCase();
    if (cleanRole == 'receptionist' || cleanRole == 'reception' || cleanRole == 'frontdesk') {
      return UserRole.reception;
    }
    if (cleanRole == 'housekeeper' || cleanRole == 'housekeeping') {
      return UserRole.housekeeping;
    }
    if (cleanRole == 'superadmin' || cleanRole == 'super_admin') {
      return UserRole.superAdmin;
    }
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == cleanRole,
      orElse: () => UserRole.reception,
    );
  }
}
