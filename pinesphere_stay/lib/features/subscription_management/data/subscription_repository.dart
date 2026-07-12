import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_repository.g.dart';

class SubscriptionInfo {
  final String planName;
  final double price;
  final DateTime renewalDate;
  final bool autoRenew;
  final String status; // active, grace_period, expired, disabled
  final String licenseKey;
  final bool isLicenseValid;

  SubscriptionInfo({
    required this.planName,
    required this.price,
    required this.renewalDate,
    required this.autoRenew,
    required this.status,
    required this.licenseKey,
    required this.isLicenseValid,
  });

  SubscriptionInfo copyWith({
    String? planName,
    double? price,
    DateTime? renewalDate,
    bool? autoRenew,
    String? status,
    String? licenseKey,
    bool? isLicenseValid,
  }) {
    return SubscriptionInfo(
      planName: planName ?? this.planName,
      price: price ?? this.price,
      renewalDate: renewalDate ?? this.renewalDate,
      autoRenew: autoRenew ?? this.autoRenew,
      status: status ?? this.status,
      licenseKey: licenseKey ?? this.licenseKey,
      isLicenseValid: isLicenseValid ?? this.isLicenseValid,
    );
  }
}

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository();
}

class SubscriptionRepository {
  Future<SubscriptionInfo> getSubscription() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SubscriptionInfo(
      planName: 'Pro Plan (Yearly)',
      price: 15000.0,
      renewalDate: DateTime.now().add(const Duration(days: 30)),
      autoRenew: true,
      status: 'active',
      licenseKey: 'PSTAY-PRO-XXXX-YYYY',
      isLicenseValid: true,
    );
  }

  Future<bool> toggleAutoRenew(bool val) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return val;
  }

  Future<bool> renewSubscription() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<bool> validateLicense(String key) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return key.startsWith('PSTAY-') && key.length > 10;
  }
}
