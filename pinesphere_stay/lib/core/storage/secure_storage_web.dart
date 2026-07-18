import 'dart:html' as html;
import 'secure_storage_service.dart';

class SecureStorageService implements ISecureStorageService {
  @override
  Future<void> write({required String key, required String value}) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    html.window.localStorage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    html.window.localStorage.clear();
  }
}
