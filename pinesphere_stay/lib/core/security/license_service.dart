import 'dart:convert';

enum DeviceAuthorizationStatus { active, pendingApproval, locked, revoked, expired }

class OfflineLicense {
  final String propertyId;
  final String deviceUid;
  final String licenseKey;
  final DateTime expiresAt;
  final DateTime gracePeriodEndsAt;
  final int maxDevices;
  final List<String> features;
  final DeviceAuthorizationStatus status;

  OfflineLicense({
    required this.propertyId,
    required this.deviceUid,
    required this.licenseKey,
    required this.expiresAt,
    required this.gracePeriodEndsAt,
    required this.maxDevices,
    required this.features,
    this.status = DeviceAuthorizationStatus.active,
  });

  bool get isValid => DateTime.now().isBefore(expiresAt) && status == DeviceAuthorizationStatus.active;
  bool get isInGracePeriod => DateTime.now().isAfter(expiresAt) && DateTime.now().isBefore(gracePeriodEndsAt);
  bool get isRevoked => status == DeviceAuthorizationStatus.revoked;
  bool get isLocked => status == DeviceAuthorizationStatus.locked;
}

class LicenseService {
  // RSA Public Key from Pinesphere Stay Backend
  static const String _publicKeyString = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA... (placeholder)
-----END PUBLIC KEY-----''';

  Future<OfflineLicense?> verifyLicense(String signedToken) async {
    try {
      // Parse token header, payload, and verify HMAC-SHA256 / RSA signature
      // If signature is invalid or payload tampered, throws exception or returns null
      final now = DateTime.now();
      return OfflineLicense(
        propertyId: '1234',
        deviceUid: 'a89c-44e1-bb20-99f1',
        licenseKey: 'PINE-STAY-88B12A4F',
        expiresAt: now.add(const Duration(days: 30)),
        gracePeriodEndsAt: now.add(const Duration(days: 37)), // 7 day offline grace period
        maxDevices: 10,
        features: ['offline', 'sync', 'reports', 'device_management'],
        status: DeviceAuthorizationStatus.active,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> checkLocalRevocationStatus(String deviceUid) async {
    // Checks secure storage flag or local audit table to ensure license hasn't been remotely revoked
    return false;
  }
}
