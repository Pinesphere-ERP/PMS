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
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == role.toLowerCase(),
      orElse: () => UserRole.guest,
    );
  }
}
