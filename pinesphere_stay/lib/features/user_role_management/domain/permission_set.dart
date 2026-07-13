import '../../../../core/permissions/permission_matrix.dart';

class PermissionSet {
  final Map<String, AccessLevel> _permissions;

  PermissionSet(this._permissions);

  factory PermissionSet.fromList(List<Map<String, dynamic>> list) {
    final Map<String, AccessLevel> permissions = {};
    for (final item in list) {
      final code = item['permission_code'] as String? ?? '';
      final levelStr = item['access_level'] as String? ?? 'NONE';
      if (code.isNotEmpty) {
        permissions[code.toUpperCase()] = _parseAccessLevel(levelStr);
      }
    }
    return PermissionSet(permissions);
  }

  static AccessLevel _parseAccessLevel(String levelStr) {
    switch (levelStr.toUpperCase()) {
      case 'NONE':
        return AccessLevel.none;
      case 'VIEW':
        return AccessLevel.view;
      case 'OWN':
      case 'LIMITED':
        return AccessLevel.limited;
      case 'UPDATESTATUS':
      case 'UPDATE_STATUS':
        return AccessLevel.updateStatus;
      case 'COLLECT':
        return AccessLevel.collect;
      case 'FULL':
        return AccessLevel.full;
      default:
        return AccessLevel.none;
    }
  }

  int _getPriority(AccessLevel level) {
    switch (level) {
      case AccessLevel.none:
        return 0;
      case AccessLevel.view:
        return 1;
      case AccessLevel.limited:
        return 2;
      case AccessLevel.updateStatus:
        return 3;
      case AccessLevel.collect:
        return 4;
      case AccessLevel.full:
        return 5;
    }
  }

  bool hasPermission(String permissionCode, AccessLevel requiredLevel) {
    final userLevel = _permissions[permissionCode.toUpperCase()] ?? AccessLevel.none;
    return _getPriority(userLevel) >= _getPriority(requiredLevel);
  }
}
