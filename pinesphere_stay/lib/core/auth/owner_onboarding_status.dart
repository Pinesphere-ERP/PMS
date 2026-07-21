/// Represents every possible state an Owner's property can be in.
/// This drives all router guards — zero ambiguity.
enum OwnerOnboardingStatus {
  /// Registration complete but wizard not submitted.
  draft,

  /// Registration complete, waiting for Super Admin approval.
  pendingApproval,

  /// Super Admin rejected the registration with a reason.
  rejected,

  /// Property approved by Super Admin; owner can now operate on trial.
  approved,

  /// Trial period active (14 days post-approval, no subscription yet).
  trial,

  /// Trial expired; subscription required before going live.
  trialExpired,

  /// Subscription active and property is fully operational.
  live,

  /// Subscription in grace period (past expiry but within grace window).
  pastDue,

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
    final ob = (onboardingStatus ?? 'pending_approval').toLowerCase();
    final sub = (subscriptionStatus ?? '').toLowerCase();

    switch (ob) {
      case 'draft':
        return OwnerOnboardingStatus.draft;
      case 'pending_approval':
        return OwnerOnboardingStatus.pendingApproval;
      case 'rejected':
        return OwnerOnboardingStatus.rejected;
      case 'approved':
      case 'completed':
        // Approved but what's the sub?
        if (sub == 'trial') return OwnerOnboardingStatus.trial;
        if (sub == 'expired') return OwnerOnboardingStatus.trialExpired;
        if (sub == 'active') return OwnerOnboardingStatus.live;
        return OwnerOnboardingStatus.approved;
      case 'live':
        if (sub == 'past_due') return OwnerOnboardingStatus.pastDue;
        if (sub == 'expired') return OwnerOnboardingStatus.subscriptionExpired;
        if (sub == 'suspended') return OwnerOnboardingStatus.suspended;
        return OwnerOnboardingStatus.live;
      default:
        return OwnerOnboardingStatus.unknown;
    }
  }

  /// Whether the owner can access the operational dashboard.
  bool get canAccessDashboard =>
      this == live || this == pastDue || this == trial;

  /// Whether the owner is fully operational (not in any degraded state).
  bool get isFullyOperational => this == live;

  /// Whether the owner needs to wait for admin action.
  bool get isWaitingForAdmin =>
      this == pendingApproval;

  /// Whether the owner needs to take subscription action.
  bool get needsSubscriptionAction =>
      this == trialExpired || this == subscriptionExpired;
}
