import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/domain/models/user_model.dart';
import '../../features/auth/domain/models/accessible_property_model.dart';
import 'owner_onboarding_status.dart';

part 'session_context.g.dart';

/// The authoritative session context for the current login.
/// Consumed by router guards and the dashboard to decide what to show.
class SessionContext {
  final UserModel? user;
  final String? activePropertyId;
  final OwnerOnboardingStatus ownerStatus;
  final bool isOwner;
  final bool isSuperAdmin;
  final List<AccessiblePropertyModel> accessibleProperties;

  const SessionContext({
    this.user,
    this.activePropertyId,
    this.ownerStatus = OwnerOnboardingStatus.unknown,
    this.isOwner = false,
    this.isSuperAdmin = false,
    this.accessibleProperties = const [],
  });

  bool get hasMultipleProperties => accessibleProperties.length > 1;

  bool get isAuthenticated => user != null;

  /// The active property, resolved from accessible list.
  AccessiblePropertyModel? get activeProperty {
    if (activePropertyId == null) return null;
    try {
      return accessibleProperties.firstWhere(
        (p) => p.propertyId == activePropertyId,
      );
    } catch (_) {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
class SessionContextNotifier extends _$SessionContextNotifier {
  @override
  SessionContext build() => const SessionContext();

  void setFromUser(UserModel user, FlutterSecureStorage storage) {
    final roleCode = (user.roleCode ?? user.role.name).toUpperCase();
    final isOwner = roleCode == 'OWNER';
    final isSuperAdmin = roleCode == 'SUPER_ADMIN';

    final ownerStatus = isOwner
        ? OwnerOnboardingStatus.fromRaw(
            onboardingStatus: user.onboardingStatus,
            subscriptionStatus: user.subscriptionStatus,
          )
        : OwnerOnboardingStatus.unknown;

    // Active property = primary property by default
    String? activePropertyId = user.propertyId;
    if (activePropertyId == null && user.accessibleProperties.isNotEmpty) {
      activePropertyId = user.accessibleProperties.first.propertyId;
    }

    state = SessionContext(
      user: user,
      activePropertyId: activePropertyId,
      ownerStatus: ownerStatus,
      isOwner: isOwner,
      isSuperAdmin: isSuperAdmin,
      accessibleProperties: user.accessibleProperties,
    );
  }

  /// Switch the active property context (multi-property owners).
  Future<void> switchProperty(String propertyId, FlutterSecureStorage storage) async {
    await storage.write(key: 'active_property_id', value: propertyId);

    final current = state;
    final prop = current.accessibleProperties.firstWhere(
      (p) => p.propertyId == propertyId,
      orElse: () => current.activeProperty ?? current.accessibleProperties.first,
    );

    final ownerStatus = OwnerOnboardingStatus.fromRaw(
      onboardingStatus: prop.onboardingStatus,
      subscriptionStatus: prop.subscriptionStatus,
    );

    state = SessionContext(
      user: current.user,
      activePropertyId: propertyId,
      ownerStatus: ownerStatus,
      isOwner: current.isOwner,
      isSuperAdmin: current.isSuperAdmin,
      accessibleProperties: current.accessibleProperties,
    );
  }

  void clear() {
    state = const SessionContext();
  }
}
