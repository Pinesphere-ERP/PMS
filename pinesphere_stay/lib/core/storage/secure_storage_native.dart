import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_storage_service.dart';

class SecureStorageService implements ISecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    webOptions: WebOptions(dbName: 'pinesphere_stay', publicKey: 'pinesphere'),
  );

  @override
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
