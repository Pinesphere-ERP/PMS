import 'package:web/web.dart' as web;
import 'secure_storage_service.dart';

class SecureStorageService implements ISecureStorageService {
  @override
  Future<void> write({required String key, required String value}) async {
    web.window.localStorage.setItem(key, value);
  }

  @override
  Future<String?> read({required String key}) async {
    return web.window.localStorage.getItem(key);
  }

  @override
  Future<void> delete({required String key}) async {
    web.window.localStorage.removeItem(key);
  }

  @override
  Future<void> deleteAll() async {
    web.window.localStorage.clear();
  }
}
