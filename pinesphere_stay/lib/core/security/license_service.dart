import 'dart:convert';
// import 'package:encrypt/encrypt.dart'; // TODO: add encrypt for RSA signature verification

class OfflineLicense {
  final String propertyId;
  final String licenseKey;
  final DateTime expiresAt;
  final int maxDevices;
  final List<String> features;

  OfflineLicense({
    required this.propertyId,
    required this.licenseKey,
    required this.expiresAt,
    required this.maxDevices,
    required this.features,
  });

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

class LicenseService {
  // RSA Public Key from Pinesphere Stay Backend
  static const String _publicKeyString = '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA... (placeholder)
-----END PUBLIC KEY-----''';

  Future<OfflineLicense?> verifyLicense(String signedToken) async {
    try {
      // Logic to verify the JWT or custom signed token using the public key
      // final parser = RSAKeyParser();
      // final publicKey = parser.parse(_publicKeyString) as RSAPublicKey;
      // final encrypter = Encrypter(RSA(publicKey: publicKey));
      
      // Parse payload
      // Verify signature
      // Return OfflineLicense
      
      return OfflineLicense(
        propertyId: '1234',
        licenseKey: 'PINESPHERE-XXX-YYY',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        maxDevices: 10,
        features: ['offline', 'sync', 'reports'],
      );
    } catch (e) {
      return null;
    }
  }
}
