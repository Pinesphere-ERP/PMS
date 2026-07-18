import 'dart:io';
import 'package:path_provider/path_provider.dart';

abstract class IFileStorageService {
  Future<String> getApplicationDocumentsPath();
  Future<String> getTemporaryPath();
}

class FileStorageService implements IFileStorageService {
  @override
  Future<String> getApplicationDocumentsPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  @override
  Future<String> getTemporaryPath() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }
}
