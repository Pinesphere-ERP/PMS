import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceInfoService {
  static const String _deviceIdKey = 'device_fingerprint';
  final FlutterSecureStorage _secureStorage;

  DeviceInfoService(this._secureStorage);

  Future<String> getDeviceFingerprint() async {
    String? deviceId = await _secureStorage.read(key: _deviceIdKey);
    
    if (deviceId == null) {
      // Generate a permanent unique UUID for this installation if not found
      deviceId = const Uuid().v4();
      await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    }
    
    return deviceId;
  }

  Future<String> getDeviceName() async {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iOS Device';
    if (Platform.isWindows) return 'Windows PC';
    if (Platform.isMacOS) return 'Mac';
    return 'Unknown Device';
  }
}
