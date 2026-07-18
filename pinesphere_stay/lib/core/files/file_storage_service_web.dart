abstract class IFileStorageService {
  Future<String> getApplicationDocumentsPath();
  Future<String> getTemporaryPath();
}

class FileStorageService implements IFileStorageService {
  @override
  Future<String> getApplicationDocumentsPath() async {
    return '/'; // Web dummy path
  }

  @override
  Future<String> getTemporaryPath() async {
    return '/tmp'; // Web dummy path
  }
}
