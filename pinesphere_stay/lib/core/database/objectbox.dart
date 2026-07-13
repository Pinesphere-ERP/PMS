import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pinesphere_stay/objectbox.g.dart';

class ObjectBox {
  late final Store store;

  ObjectBox._create(this.store);

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, "pinesphere_stay_db");
    
    Store store;
    try {
      store = await openStore(directory: dbPath);
    } catch (e) {
      // If there's a schema mismatch or corruption, delete the database and recreate it
      final dir = Directory(dbPath);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      store = await openStore(directory: dbPath);
    }
    
    return ObjectBox._create(store);
  }
}
