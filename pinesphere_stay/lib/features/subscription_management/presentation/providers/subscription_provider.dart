import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../audit/data/audit_service.dart';
import '../../data/subscription_repository.dart';

part 'subscription_provider.g.dart';

class SubscriptionState {
  final SubscriptionInfo? info;
  final bool isLoading;
  final String? error;
  final bool isRenewing;

  SubscriptionState({
    this.info,
    this.isLoading = false,
    this.error,
    this.isRenewing = false,
  });

  bool get isGracePeriod {
    if (info == null) return false;
    final now = DateTime.now();
    // Grace period starts when now > renewalDate AND within 15 days grace
    return now.isAfter(info!.renewalDate) && 
           now.isBefore(info!.renewalDate.add(const Duration(days: 15)));
  }

  int get daysRemainingInGracePeriod {
    if (info == null) return 0;
    final now = DateTime.now();
    final graceEnd = info!.renewalDate.add(const Duration(days: 15));
    if (now.isAfter(graceEnd)) return 0;
    return graceEnd.difference(now).inDays;
  }

  SubscriptionState copyWith({
    SubscriptionInfo? info,
    bool? isLoading,
    String? error,
    bool? isRenewing,
  }) {
    return SubscriptionState(
      info: info ?? this.info,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isRenewing: isRenewing ?? this.isRenewing,
    );
  }
}

@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  SubscriptionState build() {
    _fetchSubscription();
    return SubscriptionState(isLoading: true);
  }

  Future<void> _fetchSubscription() async {
    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      final info = await repository.getSubscription();
      state = SubscriptionState(info: info, isLoading: false);
    } catch (e) {
      state = SubscriptionState(error: e.toString(), isLoading: false);
    }
  }

  Future<void> toggleAutoRenew() async {
    if (state.info == null) return;
    final newValue = !state.info!.autoRenew;
    try {
      ref.read(auditServiceProvider).log(
        moduleName: 'subscription',
        actionType: 'toggle_auto_renew',
        targetEntity: 'subscription',
        targetRecordId: state.info!.licenseKey,
        newValue: {'auto_renew': newValue},
      );
      final repository = ref.read(subscriptionRepositoryProvider);
      final success = await repository.toggleAutoRenew(newValue);
      if (success && state.info != null) {
        state = state.copyWith(
          info: state.info!.copyWith(autoRenew: newValue),
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle auto-renew: $e');
    }
  }

  Future<bool> renew() async {
    if (state.info == null) return false;
    state = state.copyWith(isRenewing: true);
    try {
      ref.read(auditServiceProvider).log(
        moduleName: 'subscription',
        actionType: 'renew',
        targetEntity: 'subscription',
        targetRecordId: state.info!.licenseKey,
        newValue: {
          'previous_renewal_date': state.info!.renewalDate.toIso8601String(),
          'new_renewal_date': state.info!.renewalDate.add(const Duration(days: 365)).toIso8601String(),
        },
      );
      final repository = ref.read(subscriptionRepositoryProvider);
      final success = await repository.renewSubscription();
      if (success && state.info != null) {
        // Extend renewal date by 1 year
        final newRenewalDate = state.info!.renewalDate.add(const Duration(days: 365));
        state = state.copyWith(
          isRenewing: false,
          info: state.info!.copyWith(
            renewalDate: newRenewalDate,
            status: 'active',
          ),
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(isRenewing: false, error: 'Renewal failed: $e');
    }
    return false;
  }

  Future<bool> validateLicense(String key) async {
    try {
      final repository = ref.read(subscriptionRepositoryProvider);
      final isValid = await repository.validateLicense(key);
      if (state.info != null) {
        state = state.copyWith(
          info: state.info!.copyWith(
            licenseKey: key,
            isLicenseValid: isValid,
            status: isValid ? 'active' : 'expired',
          ),
        );
      }
      return isValid;
    } catch (e) {
      state = state.copyWith(error: 'License validation error: $e');
      return false;
    }
  }

  void disableSubscription() {
    if (state.info != null) {
      ref.read(auditServiceProvider).log(
        moduleName: 'subscription',
        actionType: 'disable_subscription',
        targetEntity: 'subscription',
        targetRecordId: state.info!.licenseKey,
        newValue: {'status': 'disabled'},
      );
      state = state.copyWith(
        info: state.info!.copyWith(
          status: 'disabled',
          isLicenseValid: false,
        ),
      );
    }
  }
}
