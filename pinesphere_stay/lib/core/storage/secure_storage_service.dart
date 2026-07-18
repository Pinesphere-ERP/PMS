export 'secure_storage_native.dart'
    if (dart.library.js_interop) 'secure_storage_web.dart';

abstract class ISecureStorageService {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<void> deleteAll();
}
