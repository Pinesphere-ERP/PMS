import 'package:flutter/services.dart';
// import 'package:local_auth/local_auth.dart'; // TODO: add local_auth dependency

class BiometricService {
  // final _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      // return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      return true; // Placeholder until local_auth is added
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      // return await _auth.authenticate(
      //   localizedReason: reason,
      //   options: const AuthenticationOptions(
      //     stickyAuth: true,
      //     biometricOnly: false, // fallback to PIN
      //   ),
      // );
      return true; // Placeholder
    } on PlatformException catch (_) {
      return false;
    }
  }
}
