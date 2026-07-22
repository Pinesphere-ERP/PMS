/// Represents every possible state an Owner's property can be in.
/// This drives all router guards — zero ambiguity.
enum OwnerOnboardingStatus {
  /// Registration complete but wizard not submitted.
  draft,

  /// Wizard submitted, waiting for payment/subscription.
  paymentPending,

  /// Subscription active and property is fully operational.
  active,

  /// Subscription fully expired, property locked.
  subscriptionExpired,

  /// Property has been suspended by Super Admin.
  suspended,

  /// Unknown / fallback.
  unknown;

  /// Derive the status from the raw strings returned by the backend.
  static OwnerOnboardingStatus fromRaw({
    required String? onboardingStatus,
    required String? subscriptionStatus,
  }) {
    final ob = (onboardingStatus ?? 'draft').toLowerCase();
    final sub = (subscriptionStatus ?? '').toLowerCase();

    switch (ob) {
      case 'draft':
        return OwnerOnboardingStatus.draft;
      case 'payment_pending':
        return OwnerOnboardingStatus.paymentPending;
      case 'active':
        if (sub == 'expired') return OwnerOnboardingStatus.subscriptionExpired;
        if (sub == 'suspended') return OwnerOnboardingStatus.suspended;
        return OwnerOnboardingStatus.active;
      default:
        return OwnerOnboardingStatus.unknown;
    }
  }

  /// Whether the owner can access the operational dashboard.
  bool get canAccessDashboard => this == active;

  /// Whether the owner is fully operational (not in any degraded state).
  bool get isFullyOperational => this == active;

  /// Whether the owner needs to wait for admin action.
  bool get isWaitingForAdmin => false;

  /// Whether the owner needs to take subscription action.
  bool get needsSubscriptionAction =>
      this == paymentPending || this == subscriptionExpired;
}
