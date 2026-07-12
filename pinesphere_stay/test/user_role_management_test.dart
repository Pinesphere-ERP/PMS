import 'package:flutter_test/flutter_test.dart';
import 'package:pinesphere_stay/core/permissions/permission_matrix.dart';
import 'package:pinesphere_stay/features/user_role_management/domain/permission_set.dart';

void main() {
  group('PermissionSet Tests', () {
    test('Should parse list and check permissions correctly', () {
      final pList = [
        {'permission_code': 'BOOKINGS', 'access_level': 'FULL'},
        {'permission_code': 'PAYMENTS', 'access_level': 'LIMITED'},
        {'permission_code': 'AUDIT_LOGS', 'access_level': 'VIEW'},
      ];

      final permissionSet = PermissionSet.fromList(pList);

      // Verify BOOKINGS (FULL) has all levels of access
      expect(permissionSet.hasPermission('BOOKINGS', AccessLevel.full), isTrue);
      expect(permissionSet.hasPermission('BOOKINGS', AccessLevel.limited), isTrue);
      expect(permissionSet.hasPermission('BOOKINGS', AccessLevel.view), isTrue);

      // Verify PAYMENTS (LIMITED) has limited and view access but NOT full access
      expect(permissionSet.hasPermission('PAYMENTS', AccessLevel.full), isFalse);
      expect(permissionSet.hasPermission('PAYMENTS', AccessLevel.limited), isTrue);
      expect(permissionSet.hasPermission('PAYMENTS', AccessLevel.view), isTrue);

      // Verify AUDIT_LOGS (VIEW) has view access but NOT limited or full access
      expect(permissionSet.hasPermission('AUDIT_LOGS', AccessLevel.limited), isFalse);
      expect(permissionSet.hasPermission('AUDIT_LOGS', AccessLevel.view), isTrue);

      // Verify unknown permission defaults to false / none
      expect(permissionSet.hasPermission('INVENTORY', AccessLevel.view), isFalse);
    });
  });
}
