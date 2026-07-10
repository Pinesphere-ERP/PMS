import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../permissions/permission_matrix.dart';

class RoleGuard extends ConsumerWidget {
  final Module module;
  final Widget child;
  final Widget? fallback;
  final AccessLevel minimumLevel;

  const RoleGuard({
    super.key,
    required this.module,
    required this.child,
    this.fallback,
    this.minimumLevel = AccessLevel.view,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.maybeWhen(
      authenticated: (user) {
        final access = PermissionMatrix.getAccessLevel(user.role, module);
        if (access.index >= minimumLevel.index) {
          return child;
        }
        return fallback ?? const SizedBox.shrink();
      },
      orElse: () => fallback ?? const SizedBox.shrink(),
    );
  }
}
